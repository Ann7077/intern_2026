import numpy as np
import scipy.signal as signal

# ==========================================
# 0. 参数配置
# ==========================================
FS = 100e6           
F_IF = 20e6          
F_JAM = 35e6         
N_SAMPLES = 1000  # 缩短点数，方便前期看波形和对数据

DDS_FREQ = 20e6      
DECIMATION_RATE = 10 

# ==========================================
# 1. ADC 数据源 (这里只取前几个点打印作为示例)
# ==========================================
t = np.arange(N_SAMPLES) / FS
if_signal = np.sin(2 * np.pi * F_IF * t) + 0.5 * np.sin(2 * np.pi * F_JAM * t)

# ==========================================
# 2. DDS 本振 & 3. 数字混频
# ==========================================
dds_phase = 2 * np.pi * DDS_FREQ * t
dds_cos = np.cos(dds_phase)
mixer_i = if_signal * dds_cos

# ==========================================
# 4. FIR 低通滤波器
# ==========================================
num_taps = 32
cutoff_freq = 1e6  
fir_coeffs = signal.firwin(num_taps, cutoff_freq, fs=FS, pass_zero='lowpass')
filtered_i = signal.lfilter(fir_coeffs, 1.0, mixer_i)

# ==========================================
# 5. 降采样
# ==========================================
baseband_i = filtered_i[::DECIMATION_RATE]

# ==========================================
# ✨ 新增：具体数据打印与导出
# ==========================================
print("--- 前 5 个采样点的具体数据（浮点未定点化） ---")
for i in range(5):
    print(f"时钟周期 [{i}]:")
    print(f"  ADC输入 (if_signal) : {if_signal[i]:.6f}")
    print(f"  DDS本地余弦 (cos)   : {dds_cos[i]:.6f}")
    print(f"  混频后 (mixer_i)    : {mixer_i[i]:.6f}")
    print(f"  FIR滤波后(filtered_i): {filtered_i[i]:.6f}")

# 导出为 txt 文件，方便后期 Verilog 仿真直接读取
np.savetxt('if_signal.txt', if_signal, fmt='%.6f')
np.savetxt('mixer_i.txt', mixer_i, fmt='%.6f')
np.savetxt('decimated_i.txt', baseband_i, fmt='%.6f')
print("\n>>> 数据已成功导出为 txt 文件!")