#!/usr/bin/env bash
set -euo pipefail

# README
# This script helps create uniform test templates for strategy validation.
# Usage:
# - Place this script in the root folder of your Hummingbot instance.
# - Run it from that same root folder:
#   - bash create_controller_config.sh
# - When the flow completes successfully, both files should be created:
#   - Controller config in conf/controllers/
#   - Script config in conf/scripts/
#
# Currently supported templates:
# - market_making.pmm_simple
# - generic.grid_strike
# More templates can be added in future updates.
#
# Recommended runtime window:
# - This setup is tuned for short monitoring runs (~15 to 30 minutes).
#
# Capital baseline:
# - Set total test capital at 100 (quote-equivalent).
#
# Grid Strike notes:
# - Allocate capital in base or quote depending on selected side:
#   - BUY side: quote allocation
#   - SELL side: base allocation
# - min_order_amount_quote defaults:
#   - 7  -> approximately 13 grids
#   - 12 -> approximately 2 grids
# - Range and entry defaults:
#   - range_distance = 1%
#   - limit_price offset = 0.5%
# - Best suited for CEX testing.
# - For DEX CLOB, tune these based on market conditions:
#   - order_frequency
#   - min_spread_between_orders
#
# PMM Simple notes:
# - Split capital 50/50 between base and quote assets.

CONTROLLER_CONFIG_DIR="conf/controllers"
SCRIPT_CONFIG_DIR="conf/scripts"

trim() {
  local s="$1"
  s="${s#${s%%[![:space:]]*}}"
  s="${s%${s##*[![:space:]]}}"
  printf '%s' "$s"
}

prompt_default() {
  local label="$1"
  local default="$2"
  local value
  read -r -p "$label [$default]: " value
  value="$(trim "$value")"
  [[ -z "$value" ]] && value="$default"
  printf '%s' "$value"
}

prompt_int() {
  local label="$1"
  local default="$2"
  local value
  while true; do
    read -r -p "$label [$default]: " value
    value="$(trim "$value")"
    [[ -z "$value" ]] && value="$default"
    if [[ "$value" =~ ^[0-9]+$ ]]; then
      printf '%s' "$value"
      return
    fi
    echo "Please enter an integer."
  done
}

prompt_position_mode() {
  local value
  while true; do
    value="$(prompt_default "position_mode (HEDGE/ONEWAY)" "HEDGE")"
    value="${value^^}"
    case "$value" in
      HEDGE|ONEWAY)
        printf '%s' "$value"
        return
        ;;
      *)
        echo "Please enter HEDGE or ONEWAY."
        ;;
    esac
  done
}

sanitize_suffix() {
  local raw="$1"
  local cleaned
  cleaned="$(printf '%s' "$raw" | tr ' ' '_' | tr -cd '[:alnum:]_-')"
  printf '%s' "$cleaned"
}

next_default_controller_id() {
  local date_prefix="$1"
  local max_n=0
  local file base num

  for file in "${CONTROLLER_CONFIG_DIR}/${date_prefix}"_pmmsimple*.yml; do
    [[ -e "$file" ]] || continue
    base="$(basename "$file" .yml)"
    if [[ "$base" =~ ^${date_prefix}_pmmsimple([0-9]+)$ ]]; then
      num="${BASH_REMATCH[1]}"
      num=$((10#$num))
      (( num > max_n )) && max_n=$num
    fi
  done

  printf '%s_pmmsimple%02d' "$date_prefix" $((max_n + 1))
}

pmm_next_script_config_filename() {
  local max_n=0
  local file base num

  for file in "${SCRIPT_CONFIG_DIR}"/conf_market_making.pmm_simple_pmmsimple*.yml; do
    [[ -e "$file" ]] || continue
    base="$(basename "$file" .yml)"
    if [[ "$base" =~ ^conf_market_making\.pmm_simple_pmmsimple([0-9]+)$ ]]; then
      num="${BASH_REMATCH[1]}"
      num=$((10#$num))
      (( num > max_n )) && max_n=$num
    fi
  done

  printf 'conf_market_making.pmm_simple_pmmsimple%02d.yml' $((max_n + 1))
}

pmm_script_config_filename_for_controller() {
  local controller_id="$1"
  local suffix="${controller_id#*_}"

  if [[ "$suffix" =~ ^pmmsimple[0-9]+$ ]]; then
    printf 'conf_market_making.pmm_simple_%s.yml' "$suffix"
  else
    pmm_next_script_config_filename
  fi
}

csv_to_yaml_float_list() {
  local csv="$1"
  IFS=',' read -r -a arr <<< "$csv"
  for item in "${arr[@]}"; do
    item="$(trim "$item")"
    [[ -n "$item" ]] && echo "- $item"
  done
}

csv_to_yaml_decimal_str_list() {
  local csv="$1"
  IFS=',' read -r -a arr <<< "$csv"
  for item in "${arr[@]}"; do
    item="$(trim "$item")"
    [[ -n "$item" ]] && echo "- '$item'"
  done
}

create_pmm_simple_config() {
  if [[ ! -d "$CONTROLLER_CONFIG_DIR" ]]; then
    echo "Output directory '$CONTROLLER_CONFIG_DIR' not found."
    exit 1
  fi
  mkdir -p "$SCRIPT_CONFIG_DIR"

  echo "Create market_making.pmm_simple controller config"
  echo "------------------------------------------------"
  echo "Note: Press Enter to accept the default value shown in [brackets]."
  echo

  date_prefix="$(date +%d%m%Y)"
  read -r -p "Enter config name suffix (blank for auto): " user_suffix
  user_suffix="$(trim "${user_suffix:-}")"

  if [[ -z "$user_suffix" ]]; then
    config_id="$(next_default_controller_id "$date_prefix")"
  else
    user_suffix="$(sanitize_suffix "$user_suffix")"
    if [[ -z "$user_suffix" ]]; then
      echo "Invalid suffix. Use letters, numbers, _ or -."
      exit 1
    fi
    config_id="${date_prefix}_${user_suffix}"
  fi

  controller_filename="${config_id}.yml"
  controller_path="${CONTROLLER_CONFIG_DIR}/${controller_filename}"

  if [[ -f "$controller_path" ]]; then
    read -r -p "File already exists: $controller_path. Overwrite? (y/N): " overwrite
    overwrite="$(trim "$overwrite")"
    if [[ "${overwrite,,}" != "y" && "${overwrite,,}" != "yes" ]]; then
      echo "Aborted."
      exit 1
    fi
  fi

  total_amount_quote="100"
  manual_kill_switch="false"
  connector_name="$(prompt_default "connector_name" "binance")"
  trading_pair="$(prompt_default "trading_pair" "BTC-FDUSD")"
  buy_spreads_csv="0.003,0.005"
  sell_spreads_csv="0.004,0.006"
  buy_amounts_pct_csv="1,1"
  sell_amounts_pct_csv="1,1"
  executor_refresh_time="$(prompt_int "executor_refresh_time (seconds)" "60")"
  cooldown_time="10"
  leverage="10"
  position_mode="$(prompt_position_mode)"
  stop_loss="0.05"
  take_profit="0.0002"
  time_limit="300"
  take_profit_order_type="$(prompt_int "take_profit_order_type (1=MARKET,2=LIMIT,3=LIMIT_MAKER)" "2")"

  buy_spreads_yaml="$(csv_to_yaml_float_list "$buy_spreads_csv")"
  sell_spreads_yaml="$(csv_to_yaml_float_list "$sell_spreads_csv")"
  buy_amounts_yaml="$(csv_to_yaml_decimal_str_list "$buy_amounts_pct_csv")"
  sell_amounts_yaml="$(csv_to_yaml_decimal_str_list "$sell_amounts_pct_csv")"

  cat > "$controller_path" <<YAML
id: ${config_id}
controller_name: pmm_simple
controller_type: market_making
total_amount_quote: '${total_amount_quote}'
manual_kill_switch: ${manual_kill_switch}
initial_positions: []
connector_name: ${connector_name}
trading_pair: ${trading_pair}
buy_spreads:
${buy_spreads_yaml}
sell_spreads:
${sell_spreads_yaml}
buy_amounts_pct:
${buy_amounts_yaml}
sell_amounts_pct:
${sell_amounts_yaml}
executor_refresh_time: ${executor_refresh_time}
cooldown_time: ${cooldown_time}
leverage: ${leverage}
position_mode: ${position_mode}
stop_loss: '${stop_loss}'
take_profit: '${take_profit}'
time_limit: ${time_limit}
take_profit_order_type: ${take_profit_order_type}
trailing_stop: null
position_rebalance_threshold_pct: '0.05'
skip_rebalance: true
YAML

  script_config_filename="$(pmm_script_config_filename_for_controller "$config_id")"
  script_config_path="${SCRIPT_CONFIG_DIR}/${script_config_filename}"

  cat > "$script_config_path" <<YAML
markets: {}
controllers_config:
- ${controller_filename}
script_file_name: v2_with_controllers.py
max_global_drawdown_quote: null
max_controller_drawdown_quote: null
YAML

  echo
  echo "Config created: $controller_path"
  echo "Script config created: $script_config_path"
}

prompt_int_choice() {
  local label="$1"
  local default="$2"
  local value
  while true; do
    read -r -p "$label [$default]: " value
    value="$(trim "$value")"
    [[ -z "$value" ]] && value="$default"
    if [[ "$value" =~ ^[0-9]+$ ]]; then
      printf '%s' "$value"
      return
    fi
    echo "Please enter an integer."
  done
}

prompt_min_order_amount_quote() {
  local value
  read -r -p "min_order_amount_quote (7 or 12) [12]: " value
  value="$(trim "$value")"
  [[ -z "$value" ]] && value="12"
  case "$value" in
    7|12)
      printf '%s' "$value"
      ;;
    *)
      echo "Invalid min_order_amount_quote. Only 7 or 12 are allowed. Exiting." >&2
      exit 1
      ;;
  esac
}

normalize_decimal() {
  local n="$1"
  awk -v x="$n" 'BEGIN {
    s = sprintf("%.10f", x + 0)
    sub(/0+$/, "", s)
    sub(/\.$/, "", s)
    print s
  }'
}

calc_end_price() {
  local start="$1"
  local dist="$2"
  awk -v s="$start" -v d="$dist" 'BEGIN { printf "%.10f", s * (1 + d) }'
}

calc_limit_price() {
  local side="$1"
  local start="$2"
  local end="$3"
  awk -v side="$side" -v s="$start" -v e="$end" 'BEGIN {
    if (side == 1) {
      printf "%.10f", s * (1 - 0.005)
    } else {
      printf "%.10f", e * (1 + 0.005)
    }
  }'
}

next_default_gridstrike_id() {
  local date_prefix="$1"
  local max_n=0
  local file base num

  for file in "${CONTROLLER_CONFIG_DIR}/${date_prefix}"_gridstrike*.yml; do
    [[ -e "$file" ]] || continue
    base="$(basename "$file" .yml)"
    if [[ "$base" =~ ^${date_prefix}_gridstrike([0-9]+)$ ]]; then
      num="${BASH_REMATCH[1]}"
      num=$((10#$num))
      if (( num > max_n )); then
        max_n=$num
      fi
    fi
  done

  printf '%s_gridstrike%02d' "$date_prefix" $((max_n + 1))
}

gridstrike_next_script_config_filename() {
  local max_n=0
  local file base num

  for file in "${SCRIPT_CONFIG_DIR}"/conf_generic.grid_strike_gridstrike*.yml; do
    [[ -e "$file" ]] || continue
    base="$(basename "$file" .yml)"
    if [[ "$base" =~ ^conf_generic\.grid_strike_gridstrike([0-9]+)$ ]]; then
      num="${BASH_REMATCH[1]}"
      num=$((10#$num))
      if (( num > max_n )); then
        max_n=$num
      fi
    fi
  done

  printf 'conf_generic.grid_strike_gridstrike%02d.yml' $((max_n + 1))
}

gridstrike_script_config_filename_for_controller() {
  local controller_id="$1"
  local suffix="${controller_id#*_}"

  if [[ "$suffix" =~ ^gridstrike[0-9]+$ ]]; then
    printf 'conf_generic.grid_strike_%s.yml' "$suffix"
  else
    gridstrike_next_script_config_filename
  fi
}

create_grid_strike_config() {
  if [[ ! -d "$CONTROLLER_CONFIG_DIR" ]]; then
    echo "Output directory '$CONTROLLER_CONFIG_DIR' not found."
    exit 1
  fi
  mkdir -p "$SCRIPT_CONFIG_DIR"

  echo "Create generic.grid_strike controller config"
  echo "-------------------------------------------"
  echo "Note: Press Enter to accept the default value shown in [brackets]."
  echo

  date_prefix="$(date +%d%m%Y)"
  read -r -p "Enter config name suffix (blank for auto): " user_suffix
  user_suffix="$(trim "${user_suffix:-}")"
  if [[ -z "$user_suffix" ]]; then
    config_id="$(next_default_gridstrike_id "$date_prefix")"
  else
    user_suffix="$(sanitize_suffix "$user_suffix")"
    if [[ -z "$user_suffix" ]]; then
      echo "Invalid suffix. Use letters, numbers, _ or -." >&2
      exit 1
    fi
    config_id="${date_prefix}_${user_suffix}"
  fi

  output_filename="${config_id}.yml"
  output_path="${CONTROLLER_CONFIG_DIR}/${output_filename}"

  if [[ -f "$output_path" ]]; then
    read -r -p "File already exists: $output_path. Overwrite? (y/N): " overwrite
    overwrite="$(trim "$overwrite")"
    if [[ "${overwrite,,}" != "y" && "${overwrite,,}" != "yes" ]]; then
      echo "Aborted."
      exit 1
    fi
  fi

  total_amount_quote="100"
  manual_kill_switch="false"
  leverage="10"

  position_mode="$(prompt_position_mode)"
  connector_name="$(prompt_default "connector_name" "binance")"
  trading_pair="$(prompt_default "trading_pair" "BTC-FDUSD")"

  side="$(prompt_int_choice "side (1=BUY, 2=SELL)" "1")"
  range_distance="0.01"
  start_price="$(prompt_default "start_price" "1.4")"
  end_price="$(calc_end_price "$start_price" "$range_distance")"
  end_price="$(normalize_decimal "$end_price")"
  limit_price="$(calc_limit_price "$side" "$start_price" "$end_price")"
  limit_price="$(normalize_decimal "$limit_price")"
  echo "Calculated end_price: ${end_price} (range $(awk -v d="$range_distance" 'BEGIN { printf "%.0f", d * 100 }')%)"
  echo "Calculated limit_price: ${limit_price}"

  min_spread_between_orders="0.0003"
  min_order_amount_quote="$(prompt_min_order_amount_quote)"

  max_open_orders="2"
  max_orders_per_batch="1"
  order_frequency="$(prompt_int_choice "order_frequency (seconds)" "5")"
  activation_bounds="0.003"
  keep_position="false"

  take_profit="0.0002"
  take_profit_order_type="1"

  cat > "$output_path" <<YAML
id: ${config_id}
controller_name: grid_strike
controller_type: generic
total_amount_quote: '${total_amount_quote}'
manual_kill_switch: ${manual_kill_switch}
initial_positions: []
leverage: ${leverage}
position_mode: ${position_mode}
connector_name: ${connector_name}
trading_pair: ${trading_pair}
side: ${side}
start_price: '${start_price}'
end_price: '${end_price}'
limit_price: '${limit_price}'
min_spread_between_orders: '${min_spread_between_orders}'
min_order_amount_quote: '${min_order_amount_quote}'
max_open_orders: ${max_open_orders}
max_orders_per_batch: ${max_orders_per_batch}
order_frequency: ${order_frequency}
activation_bounds: ${activation_bounds}
keep_position: ${keep_position}
triple_barrier_config:
  open_order_type: 3
  stop_loss: null
  stop_loss_order_type: 1
  take_profit: '${take_profit}'
  take_profit_order_type: ${take_profit_order_type}
  time_limit: null
  time_limit_order_type: 1
  trailing_stop: null
YAML

  script_config_filename="$(gridstrike_script_config_filename_for_controller "$config_id")"
  script_config_path="${SCRIPT_CONFIG_DIR}/${script_config_filename}"

  cat > "$script_config_path" <<YAML
markets: {}
controllers_config:
- ${output_filename}
script_file_name: v2_with_controllers.py
max_global_drawdown_quote: null
max_controller_drawdown_quote: null
YAML

  echo
  echo "Config created: $output_path"
  echo "Script config created: $script_config_path"
}

echo "Select controller to create:"
echo
echo "1. market_making.pmm"
echo "2. generic.grid_strike"
echo
read -r -p "Enter your choice: " choice

case "$choice" in
  1)
    echo
    create_pmm_simple_config
    ;;
  2)
    echo
    create_grid_strike_config
    ;;
  *)
    echo "Invalid choice. Exiting." >&2
    exit 1
    ;;
esac
