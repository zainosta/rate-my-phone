#!/bin/bash
echo "=== Delta Force Mobile Performance Auto-Rating ==="

SCORE=0

# --- CPU check ---
MAX_CPU=$(cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_max_freq 2>/dev/null | sort -nr | head -n1)
MAX_CPU=${MAX_CPU:-0}
CORE_COUNT=$(grep -c ^processor /proc/cpuinfo 2>/dev/null)
CORE_COUNT=${CORE_COUNT:-1}

if [ "$MAX_CPU" -ge 2800000 ]; then
  SCORE=$((SCORE+25))
elif [ "$MAX_CPU" -ge 2200000 ]; then
  SCORE=$((SCORE+20))
elif [ "$MAX_CPU" -ge 1700000 ]; then
  SCORE=$((SCORE+15))
else
  SCORE=$((SCORE+10))
fi

if [ "$CORE_COUNT" -ge 8 ]; then
  SCORE=$((SCORE+10))
elif [ "$CORE_COUNT" -ge 6 ]; then
  SCORE=$((SCORE+7))
else
  SCORE=$((SCORE+5))
fi

# --- RAM check ---
TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM=${TOTAL_RAM:-0}
if [ "$TOTAL_RAM" -ge 6000000 ]; then
  SCORE=$((SCORE+25))
elif [ "$TOTAL_RAM" -ge 4000000 ]; then
  SCORE=$((SCORE+20))
elif [ "$TOTAL_RAM" -ge 3000000 ]; then
  SCORE=$((SCORE+15))
else
  SCORE=$((SCORE+10))
fi

# --- GPU check ---
GPU=$(getprop ro.hardware)
GPU=${GPU:-"Unknown GPU"}

if echo "$GPU" | grep -qi "Adreno (7"; then
  SCORE=$((SCORE+25))
elif echo "$GPU" | grep -qi "Adreno (6"; then
  SCORE=$((SCORE+20))
elif echo "$GPU" | grep -qi "Mali-G7"; then
  SCORE=$((SCORE+20))
else
  SCORE=$((SCORE+15))
fi

# --- FPS check ---
FPS_LIST=$(dumpsys display | grep -i "mBaseDisplayInfo" | grep -oE "fps=[0-9]+" | grep -oE "[0-9]+")
FPS=$(echo "$FPS_LIST" | sort -nr | head -n1)
FPS=${FPS:-60}  # fallback 60 if not detected

if [ "$FPS" -ge 120 ]; then
  SCORE=$((SCORE+15))
elif [ "$FPS" -ge 90 ]; then
  SCORE=$((SCORE+10))
elif [ "$FPS" -ge 60 ]; then
  SCORE=$((SCORE+7))
else
  SCORE=$((SCORE+5))
fi

# --- Thermal state ---
THERM=$(dumpsys thermalservice 2>/dev/null | grep -i status | head -n1)
THERM=${THERM:-"Unknown"}
if echo "$THERM" | grep -qi "nominal"; then
  SCORE=$((SCORE+5))
elif echo "$THERM" | grep -qi "light"; then
  SCORE=$((SCORE+3))
else
  SCORE=$((SCORE+1))
fi

# --- Clamp final score ---
if [ "$SCORE" -gt 100 ]; then SCORE=100; fi

# --- Rating messages ---
get_rating() {
  case $1 in
    [0-9]|10) echo "🔴 Low performance – Time to upgrade your device!" ;;
    1[1-9]|20) echo "🟠 Fair – Can play but not smooth" ;;
    2[1-9]|30) echo "🟡 Average – Decent, but may lag in heavy games" ;;
    3[1-9]|40) echo "🟢 Good – Smooth gameplay possible" ;;
    4[1-9]|50) echo "🟢 Good+ – Enjoy your games!" ;;
    5[1-9]|60) echo "💚 Very Good – Nice performance, keep gaming!" ;;
    6[1-9]|70) echo "💙 Excellent – Your device is a gaming champ!" ;;
    7[1-9]|80) echo "💙🔥 Top Tier – Ultra smooth gameplay!" ;;
    8[1-9]|90) echo "💎 Legendary – Maximum performance unlocked!" ;;
    9[0-9]|100) echo "🚀 WOW PRO – You can run anything at full speed!" ;;
    *) echo "ℹ️ Unknown rating" ;;
  esac
}

RATING_MSG=$(get_rating "$SCORE")

# --- Final Output ---
echo "Your Gaming Performance Score: $SCORE / 100"
echo "$RATING_MSG"
echo "Details:"
echo "- CPU max freq: $MAX_CPU Hz ($CORE_COUNT cores)"
echo "- RAM total: $TOTAL_RAM KB"
echo "- GPU: $GPU"
echo "- Display max FPS: $FPS"
echo "- Thermal: $THERM"
echo "==============================================="
