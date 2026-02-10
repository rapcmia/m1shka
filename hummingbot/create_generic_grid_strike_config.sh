#!/usr/bin/env bash
set -euo pipefail

# README
# 1) Create this script in the root project folder, sample below:
#    /home/hummingbot/my_hummingbot
# 2) Make it executable (one time):
#    chmod +x create_generic_grid_strike_config.sh
# 3) Run from the root project folder:
#    bash create_generic_grid_strike_config.sh
#    or
#    ./create_generic_grid_strike_config.sh
#
# Output:
# - Writes config files to: conf/controllers/
# - Writes script configs to: conf/scripts/
# - Filename and id pattern: DDMMYYYY_<suffix>.yml

DEFAULT_OUTPUT_DIR="conf/controllers"
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
  if [[ -z "$value" ]]; then
    printf '%s' "$default"
  else
    printf '%s' "$value"
  fi
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

prompt_required() {
  local label="$1"
  local value
  while true; do
    read -r -p "$label: " value
    value="$(trim "$value")"
    if [[ -n "$value" ]]; then
      printf '%s' "$value"
      return
    fi
    echo "Value is required." >&2
  done
}

prompt_bool() {
  local label="$1"
  local default="$2"
  local value
  while true; do
    read -r -p "$label (true/false) [$default]: " value
    value="$(trim "$value")"
    [[ -z "$value" ]] && value="$default"
    case "${value,,}" in
      true|false)
        printf '%s' "${value,,}"
        return
        ;;
      *)
        echo "Please enter true or false."
        ;;
    esac
  done
}

prompt_nullable_number() {
  local label="$1"
  local default="$2"
  local value
  read -r -p "$label (number or null) [$default]: " value
  value="$(trim "$value")"
  [[ -z "$value" ]] && value="$default"
  if [[ "${value,,}" == "null" ]]; then
    printf '%s' "null"
  else
    printf '%s' "$value"
  fi
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

prompt_range_distance() {
  local value
  read -r -p "range_distance from start_price (1 to 3 percent) [1]: " value
  value="$(trim "${value:-}")"
  [[ -z "$value" ]] && value="1"

  if [[ ! "$value" =~ ^[0-9]+$ ]]; then
    echo "Invalid range distance. Use 1, 2, or 3." >&2
    exit 1
  fi

  if (( value > 3 )); then
    echo "Range distance above 3% is not possible for this template. Exiting." >&2
    exit 1
  fi

  if (( value < 1 )); then
    echo "Invalid range distance. Use 1, 2, or 3." >&2
    exit 1
  fi

  awk -v p="$value" 'BEGIN { printf "%.2f", p / 100 }'
}

normalize_decimal() {
  local n="$1"
  # Removes trailing zeros and trailing dot.
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

sanitize_suffix() {
  local raw="$1"
  local cleaned
  cleaned="$(printf '%s' "$raw" | tr ' ' '_' | tr -cd '[:alnum:]_-')"
  printf '%s' "$cleaned"
}

next_default_config_id() {
  local date_prefix="$1"
  local max_n=0
  local file base num

  for file in "${DEFAULT_OUTPUT_DIR}/${date_prefix}"_test*.yml; do
    [[ -e "$file" ]] || continue
    base="$(basename "$file" .yml)"
    if [[ "$base" =~ ^${date_prefix}_test([0-9]+)$ ]]; then
      num="${BASH_REMATCH[1]}"
      num=$((10#$num))
      if (( num > max_n )); then
        max_n=$num
      fi
    fi
  done

  printf '%s_test%02d' "$date_prefix" $((max_n + 1))
}

next_script_config_filename() {
  local max_n=0
  local file base num

  for file in "${SCRIPT_CONFIG_DIR}"/conf_generic.grid_strike_test*.yml; do
    [[ -e "$file" ]] || continue
    base="$(basename "$file" .yml)"
    if [[ "$base" =~ ^conf_generic\.grid_strike_test([0-9]+)$ ]]; then
      num="${BASH_REMATCH[1]}"
      num=$((10#$num))
      if (( num > max_n )); then
        max_n=$num
      fi
    fi
  done

  printf 'conf_generic.grid_strike_test%02d.yml' $((max_n + 1))
}

script_config_filename_for_controller() {
  local controller_id="$1"
  local suffix="${controller_id#*_}"

  if [[ "$suffix" =~ ^test[0-9]+$ ]]; then
    printf 'conf_generic.grid_strike_%s.yml' "$suffix"
  else
    next_script_config_filename
  fi
}

if [[ ! -d "$DEFAULT_OUTPUT_DIR" ]]; then
  echo "Output directory '$DEFAULT_OUTPUT_DIR' not found."
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
  config_id="$(next_default_config_id "$date_prefix")"
else
  user_suffix="$(sanitize_suffix "$user_suffix")"
  if [[ -z "$user_suffix" ]]; then
    echo "Invalid suffix. Use letters, numbers, _ or -." >&2
    exit 1
  fi
  config_id="${date_prefix}_${user_suffix}"
fi

output_filename="${config_id}.yml"
output_path="${DEFAULT_OUTPUT_DIR}/${output_filename}"

if [[ -f "$output_path" ]]; then
  read -r -p "File already exists: $output_path. Overwrite? (y/N): " overwrite
  overwrite="$(trim "$overwrite")"
  if [[ "${overwrite,,}" != "y" && "${overwrite,,}" != "yes" ]]; then
    echo "Aborted."
    exit 1
  fi
fi

total_amount_quote="$(prompt_default "total_amount_quote (quote budget)" "100")"
manual_kill_switch="$(prompt_bool "manual_kill_switch" "false")"
leverage="$(prompt_int_choice "leverage" "20")"

position_mode="$(prompt_position_mode)"

connector_name="$(prompt_default "connector_name" "xrpl")"
trading_pair="$(prompt_default "trading_pair" "XRP-RLUSD")"

side="$(prompt_int_choice "side (1=BUY, 2=SELL)" "1")"
range_distance="$(prompt_range_distance)"
start_price="$(prompt_default "start_price" "1.4")"
end_price="$(calc_end_price "$start_price" "$range_distance")"
end_price="$(normalize_decimal "$end_price")"
limit_price="$(calc_limit_price "$side" "$start_price" "$end_price")"
limit_price="$(normalize_decimal "$limit_price")"
echo "Calculated end_price: ${end_price} (range $(awk -v d="$range_distance" 'BEGIN { printf "%.0f", d * 100 }')%)"
echo "Calculated limit_price: ${limit_price}"

min_spread_between_orders="$(prompt_default "min_spread_between_orders" "0.005")"
min_order_amount_quote="$(prompt_default "min_order_amount_quote" "6")"

max_open_orders="$(prompt_int_choice "max_open_orders" "2")"
max_orders_per_batch="$(prompt_int_choice "max_orders_per_batch" "1")"
order_frequency="$(prompt_int_choice "order_frequency (seconds)" "60")"
activation_bounds="$(prompt_nullable_number "activation_bounds" "0.005")"
keep_position="$(prompt_bool "keep_position" "false")"

take_profit="$(prompt_default "triple_barrier.take_profit" "0.001")"
take_profit_order_type="$(prompt_int_choice "triple_barrier.take_profit_order_type" "3")"

cat > "$output_path" <<YAML
id: ${config_id}
controller_name: grid_strike
controller_type: generic
total_amount_quote: '${total_amount_quote}'
manual_kill_switch: ${manual_kill_switch}
candles_config: []
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

script_config_filename="$(script_config_filename_for_controller "$config_id")"
script_config_path="${SCRIPT_CONFIG_DIR}/${script_config_filename}"

cat > "$script_config_path" <<YAML
markets: {}
candles_config: []
controllers_config:
- ${output_filename}
script_file_name: v2_with_controllers.py
max_global_drawdown_quote: null
max_controller_drawdown_quote: null
YAML

echo
echo "Config created: $output_path"
echo "Script config created: $script_config_path"
