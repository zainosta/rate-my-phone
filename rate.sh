echo "=== Delta Force Mobile Performance Auto-Rating ==="

SCORE=0

# --- CPU check ---
MAX_CPU=$(cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_max_freq | sort -nr | head -n1)
CORE_COUNT=$(grep -c ^processor /proc/cpuinfo)

if [ "$MAX_CPU" -ge 2800000 ]; then
  SCORE=$((SCORE+25)) # flagship
elif [ "$MAX_CPU" -ge 2200000 ]; then
  SCORE=$((SCORE+20)) # high mid
elif [ "$MAX_CPU" -ge 1700000 ]; then
  SCORE=$((SCORE+15)) # mid
else
  SCORE=$((SCORE+10)) # low
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
GPU=$(dumpsys SurfaceFlinger | grep -i GLES | head -n1)
if echo "$GPU" | grep -qi "Adreno (7"; then
  SCORE=$((SCORE+25))
elif echo "$GPU" | grep -qi "Adreno (6"; then
  SCORE=$((SCORE+20))
elif echo "$GPU" | grep -qi "Mali-G7"; then
  SCORE=$((SCORE+20))
else
  SCORE=$((SCORE+15))
fi

# --- Display FPS check ---
FPS=$(dumpsys SurfaceFlinger | grep -i fps | grep -oE "[0-9]+" | sort -nr | head -n1)
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
THERM=$(dumpsys thermalservice | grep -i status | head -n1)
if echo "$THERM" | grep -qi "nominal"; then
  SCORE=$((SCORE+5))
elif echo "$THERM" | grep -qi "light"; then
  SCORE=$((SCORE+3))
else
  SCORE=$((SCORE+1))
fi

# --- Final Result ---
if [ "$SCORE" -gt 100 ]; then SCORE=100; fi

echo "Your Gaming Performance Score: $SCORE / 100"
echo "Details:"
echo "- CPU max freq: $MAX_CPU Hz ($CORE_COUNT cores)"
echo "- RAM total: $TOTAL_RAM KB"
echo "- GPU: $GPU"
echo "- Display max FPS: $FPS"
echo "- Thermal: $THERM"
echo "==============================================="
