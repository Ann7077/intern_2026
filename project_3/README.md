# Overall DDC
The purpose of a Digital Down Converter (DDC) is to take a received high-frequency signal and convert it back down to a low-frequency signal. Because low-frequency data is originally transmitted using a high-frequency carrier wave for convenience, the DDC process reverses this so the original low-frequency information can be recovered.

To process the signal, the receiver multiplies the incoming high-frequency signal with a locally generated signal inside a mixer, which splits the signal into high-frequency and low-frequency components. Next, a lowpass filter removes the unwanted high-frequency part, leaving only the low-frequency signal. Finally, the signal is sent through a decimator to reduce its sampling rate.

## Goal
The goal is to convert a high-frequency real intermediate frequency (IF) signal into a complex baseband signal ($I/Q$ data) by removing the high-frequency carrier wave.

$$
a(t) \cos (\omega_ct + \phi(t)) \longrightarrow a(t)e^{j\phi(t)} = a(t)\cos(\phi(t))+ja(t)\sin(\phi(t))
$$

Our input signal is `i_if_signal` from `ddc_top_tb.sv`, which equals 
$$
\underbrace{1000\cos(2\pi\cdot 20\text{ MHz}\cdot t)}_{\text{target signal}} + \underbrace{800\cos(2\pi\cdot 35\text{ MHz}\cdot t)}_{\text{interference signal}}
$$

## Overall diagram
![DDC_diagram.png](<vx_images/DDC_diagram.png>)



# DDS (`dds.sv`)

## 1. What Does This File Do?

The `dds.sv` file creates a clean, smooth digital sine (`dds_sin`) and cosine (`dds_cos`) waves inside the FPGA. The rest of the DDC system uses these generated waves like a radio tuner to lock onto the incoming high-frequency signal and translate it down to a readable baseband frequency.


## 2. Inputs & Outputs Overview

| Signal Name | Input or Output? | Bit Size | Simple Meaning & Purpose |
| --- | --- | --- | --- |
| `clk` | Input | 1 bit | The main heartbeat clock running at $100\text{ MHz}$ |
| `rst_n` | Input | 1 bit | The reset button (clears memory when turned off). |
| `ftw` | Input | 32 bits | **Frequency Tuning Word:** The digital knob that sets how fast the wave oscillates. |
| `init_phase` | Input | 32 bits | Sets where the wave starts its cycle after a reset. |
| `dds_sin` | Output | 12 bits | The generated sine wave output stream. |
| `dds_cos` | Output | 12 bits | The generated cosine wave output stream. |


## 3. Step-by-Step From Input to Output

1. **Step Forward:** On every clock tick, a 32-bit counter (`phase_acc`) takes a step forward by adding the value of `ftw`.
2. **Find the Angle:** The top 10 bits of this counter tell us our current position (angle) on a $360^\circ$ circle.
3. **Look Up the Value:** The module looks up that angle in a pre-stored lookup table (`lut_rom`), which holds 1024 points of a pre-calculated sine wave.
4. **Shift for Cosine:** To make a cosine wave at the same time, the module shifts the angle forward by $90^\circ$ ($\pi/2$ radians) and reads the table again.
5. **Send Out Data:** The numbers retrieved from the lookup table are sent out as 12-bit signed digital wave values on every clock cycle.


## 4. Mathematical Proofs: Why Numbers Are Set This Way

**How do we set `ftw` to get a target $20\text{ MHz}$ carrier wave?**
The 32-bit counter wraps around after $2^{32}$ steps (a full $360^\circ$ circle). To find out how big each step (`FTW`) needs to be to make a $20\text{ MHz}$ wave out of a $100\text{ MHz}$ clock, we use this ratio:

$$
\text{FTW} = \frac{\text{Target Frequency}}{\text{Clock Frequency}} \times 2^{32}
$$

Plugging in our values ($20\text{ MHz}$ target, $100\text{ MHz}$ clock):

$$
\text{FTW} = \frac{20}{100} \times 4,294,967,296 = 0.2 \times 4,294,967,296 = 858,993,459
$$

Adding $858,993,459$ on every clock cycle makes the counter complete a full sine wave cycle once every 5 clock ticks ($100 / 20 = 5$).

**Why do we add $2^{30}$ to get the Cosine wave?**
A cosine wave is just a sine wave shifted ahead by a quarter of a full turn ($90^\circ$ out of $360^\circ$):

$$
\cos(\theta) = \sin(\theta + 90^\circ)
$$

Since a full turn ($360^\circ$) equals $2^{32}$ steps, a quarter turn ($90^\circ$) equals:

$$
\frac{1}{4} \times 2^{32} = 2^{30} = \text{\texttt{1'b1 << 30}}
$$

Adding $2^{30}$ directly to the counter gives us the exact address for the cosine wave without needing a second lookup table.


## 5. Expetation vs Result

* **What to Expect:** Both `dds_sin` and `dds_cos` should look like smooth, repeating wave patterns oscillating up and down between $-2047$ and $+2047$. Each full wave cycle should take exactly 5 clock ticks ($50\text{ ns}$). The cosine wave should peak about $1.25$ clock ticks ($90^\circ$) ahead of the sine wave.
* **Verification Against Results:** Looking at the wave image, `dds_sin` and `dds_cos` form matching high-frequency waves with the correct $90^\circ$ offset between them.



# Mixer (`mixer.v`)

## 1. What Does This File Do?

The `mixer.v` file takes the incoming high-frequency radio signal (`adc_data`) and multiplies it by the custom sine and cosine waves generated by the DDS module. This multiplication process shifts the high-frequency radio signal down into a low-frequency baseband signal so the system can easily extract the original data.


## 2. Inputs & Outputs Overview

| Signal Name | Input or Output? | Bit Size | Simple Meaning & Purpose |
| --- | --- | --- | --- |
| `adc_data` | Input | 12 bits | The incoming digital radio signal from the ADC. |
| `dds_cos` | Input | 12 bits | The reference cosine wave coming from `dds.sv`. |
| `dds_sin` | Input | 12 bits | The reference sine wave coming from `dds.sv`. |
| `i_out` | Output | 24 bits | **In-Phase ($I$) Output:** The signal multiplied by the cosine wave. |
| `q_out` | Output | 24 bits | **Quadrature ($Q$) Output:** The signal multiplied by the sine wave. |


## 3. Step-by-Step From Input to Output

1. **Receive Signals:** On every clock cycle, the mixer receives a new 12-bit sample from `adc_data`, along with 12-bit samples from `dds_cos` and `dds_sin`.
2. **Multiply for $I$ Branch:** The module multiplies `adc_data` directly with `dds_cos` to generate the 24-bit output `i_out`.
3. **Multiply for $Q$ Branch:** The module multiplies `adc_data` directly with `dds_sin` to generate the 24-bit output `q_out`.
4. **Output Growth:** Multiplying two 12-bit numbers produces a 24-bit number ($12 + 12 = 24$), keeping every bit of accuracy without losing data.


## 4. Mathematical Proofs: Why Signal Multiplication Works

**Why does multiplying signals shift the frequency down?**
Let's represent our incoming signal as a wave with frequency $\omega_c$ carrying some data phase $\phi(t)$:

$$
\text{adc\\_data} = \cos(\omega_c t + \phi(t))
$$

When we multiply this incoming wave by our local cosine wave $\cos(\omega_c t)$, we use the classic trigonometric product identity:

$$
\cos(A) \cdot \cos(B) = \frac{1}{2}\cos(A - B) + \frac{1}{2}\cos(A + B)
$$

Plugging in our waves for the In-Phase ($I$) branch:

$$
\begin{aligned}
\text{i\\_out} &= \cos(\omega_c t + \phi(t)) \cdot \cos(\omega_c t) \\
               &= \frac{1}{2}\cos(\phi(t)) + \frac{1}{2}\cos(2\omega_c t + \phi(t)) \\
\end{aligned}
$$

Notice what happens:

* **The First Part $\frac{1}{2}\cos(\phi(t))$:** The carrier frequency $\omega_c$ cancels out completely ($\omega_c - \omega_c = 0$), leaving us with our clean, low-frequency baseband data!

* **The Second Part $\frac{1}{2}\cos(2\omega_c t + \phi(t))$:** This creates a high-frequency ripple at double the carrier frequency ($2\omega_c$), which gets easily cleaned up by the next stage filter.

Doing the exact same steps with the sine wave for the Quadrature ($Q$) branch gives us:

$$
\text{q\\_out} = \cos(\omega_c t + \phi(t)) \cdot \sin(\omega_c t) = \frac{1}{2}\sin(2\omega_c t + \phi(t)) - \frac{1}{2}\sin(\phi(t))
$$


## 5. Expetation vs Result

* **What to Expect:** `i_out` and `q_out` should look like fast-moving, high-frequency ripples riding along a slow, sweeping wave baseline. The fast ripple represents the double-frequency term ($2\omega_c$), while the slow sweeping shape underneath is our actual extracted baseband data.
* **Verification Against Results:** In the simulation output, `i_out` and `q_out` show dense, fast oscillations fluctuating around a smooth sinusoidal center line, confirming the multiplication process works as intended.



# FIR Filter (`fir_filter.sv`)

## 1. What Does This File Do?

The `fir_filter.sv` file acts as a noise cleaner. After the mixer creates baseband signals, it also leaves behind unwanted high-frequency ripples ($2\omega_c$). This module uses a Finite Impulse Response (FIR) low-pass filter to smooth out those fast oscillations, letting only the clean, low-frequency data pass through.


## 2. Inputs & Outputs Overview

| Signal Name | Input or Output? | Bit Size | Simple Meaning & Purpose |
| --- | --- | --- | --- |
| `clk` | Input | 1 bit | The main system clock running at $100\text{ MHz}$. |
| `rst_n` | Input | 1 bit | The active-low reset button. |
| `i_data` | Input | 24 bits | The noisy 24-bit signal coming straight from the mixer (`i_out` or `q_out`). |
| `i_coeffs` | Input | Array (32 × 12 bits) | The "filter recipe"—32 pre-calculated numbers that define which frequencies pass through. |
| `o_data` | Output | 38 bits | The cleaned-up, high-precision filtered baseband signal. |


## 3. Step-by-Step From Input to Output

1. **Shift History:** On every clock tick, the new incoming sample from `i_data` enters a line of 32 memory registers (called taps), shifting older samples down the chain.
2. **Multiply Taps:** The module multiplies each stored sample by its matching filter coefficient from `i_coeffs`.
3. **Add Together:** All 32 multiplication results are summed together in a single step using internal multiply-accumulate (MAC) units.
4. **Expand Precision:** Summing thirty-two 24-bit values multiplied by 12-bit coefficients grows the number size to 38 bits ($24 + 12 + \text{extra bits for addition} = 38$), preventing math overflow.
5. **Output Clean Wave:** The final 38-bit sum is sent out as `o_data` on every clock cycle.


### MAC (Multiply-Accumulate)
The `mac_fir` module is the fundamental building block of the FIR filter. It handles the two core operations of digital filtering: signed multiplication and accumulation.

#### Processing Pipeline
1. **Stage 1 (Multiplication):** Multiplies 12-bit input data (`i_data`) with its 12-bit coefficient (`i_coeff`) to produce a 24-bit product (`r_mult_res`).
2. **Pipeline Synchronization:** Registers the incoming cascade sum (`i_cascade_in_d1`) to align data timing with the multiplier output.
3. **Stage 2 (Accumulation):** Adds the current multiplication product (`r_mult_res`) to the synchronized cascade sum from the previous stage to generate `o_cascade_out`.


## 4. Mathematical Proofs: Why the High Frequency Disappears

**How does the filter math cancel out the unwanted ripple?**
The FIR filter performs discrete convolution in time:

$$
\text{o\\_data}[n] = \sum_{k=0}^{31} b_k \cdot \text{i\\_data}[n-k]
$$

Where $b_k$ represents the filter coefficients.

From the mixer step, our input `i_data` contains two parts—a slow baseband signal and a high-frequency ripple:

$$
\text{i\\_data} = \underbrace{\frac{1}{2}\cos(\phi(t))}_{\text{Desired Baseband}} + \underbrace{\frac{1}{2}\cos(2\omega_c t + \phi(t))}_{\text{Unwanted Ripple}}
$$

When passed into the low-pass filter ($\text{LPF}$), coefficients $b_k$ are mathematically designed to block frequencies at or above $2\omega_c$:

$$
\begin{aligned}
\text{o\\_data} &= \text{LPF} \left\\{ \frac{1}{2}\cos(\phi(t)) + \frac{1}{2}\cos(2\omega_c t + \phi(t)) \right\\}  \\
                &= \frac{1}{2}\cos(\phi(t)) + 0 \\
                &= \frac{1}{2}\cos(\phi(t)) \\
\end{aligned}
$$

The high-frequency term $\frac{1}{2}\cos(2\omega_c t + \phi(t))$ drops to zero, leaving only the pure baseband data!


## 5. Expetation vs Result

* **What to Expect:** `o_data` should look like a completely smooth, slow sine wave. Unlike the mixer output, all fuzzy high-frequency noise and rapid ripples should be entirely gone.
* **Verification Against Results:** In the simulation plots, `o_data` appears as a smooth sinusoidal curve, confirming that the filter successfully stripped away the double-frequency ripple.



# Decimator (`decimator_b.sv`)

## 1. What Does This File Do?

The `decimator_b.sv` file acts as a **smart data downsampler**. Now that the FIR filter has cleaned up the signal, we still have $100\text{ million}$ samples coming in every second ($100\text{ MSPS}$). Because our slow baseband signal doesn't need that many data points to stay accurate, the decimator safely reduces the sample rate by a factor of 10 down to $10\text{ million}$ samples per second ($10\text{ MSPS}$).


## 2. Inputs & Outputs Overview

| Signal Name | Input or Output? | Bit Size | Simple Meaning & Purpose |
| --- | --- | --- | --- |
| `clk` | Input | 1 bit | The main system clock running at $100\text{ MHz}$. |
| `rst_n` | Input | 1 bit | The active-low reset button. |
| `i_data` | Input | 24 bits | The cleaned baseband data stream coming in at full speed. |
| `i_coeffs` | Input | Sub-filter array | Pre-defined coefficients used by the internal sub-filter branches. |
| `o_decimated_data` | Output | 38 bits | The downsampled output data stream operating at $1/10\text{th}$ the rate. |
| `o_data_valid` | Output | 1 bit | **Valid Strobe:** A flag that turns ON for 1 clock cycle every 10 ticks to mark a new sample. |


## 3. How the Input Becomes the Output (Step-by-Step)

1. **Collect High-Speed Samples:** The module accepts incoming samples on every clock cycle at $100\text{ MHz}$.
2. **Polyphase Implementation (External Reference):** I do not fully understand the intricate mathematical mechanics of how polyphase filtering works under the hood. Rather than attempting to explain the complex sub-filtering math, I relied on external reference code and established designs to implement this polyphase structure in the module.
3. **Count Clock Cycles:** An internal counter tracks incoming clock cycles from 1 to 10.
4. **Hold & Pulse:** On every 10th clock cycle, the module updates `o_decimated_data` with the latest processed value and pulses `o_data_valid` HIGH for 1 cycle.
5. **Hold Value:** During the 9 clock cycles in between, the output holds its previous value steady while waiting for the next 10th tick.

**Reference:** 
Page 8 of  [Notes_about_Basic_Polyphase_Decimation_Filters.pdf](vx_images/Notes_about_Basic_Polyphase_Decimation_Filters.pdf)


## 4. Mathematical Proofs: Why Downsampling Rate Reduction Works

**How does keeping 1 out of every 10 samples change the sample rate?**
Decimation by a factor of $M = 10$ means taking a signal sampled at clock frequency $F_{s,\text{in}} = 100\text{ MHz}$ and dropping the sample frequency down to $F_{s,\text{out}}$:

$$
F_{s,\text{out}} = \frac{F_{s,\text{in}}}{M} = \frac{100\text{ MHz}}{10} = 10\text{ MHz}
$$

In time-domain notation, if $x[n]$ is our filtered input sequence, the decimated output sequence $y[m]$ takes every 10th sample:

$$
y[m] = x[m \cdot 10] \quad \text{where } m = 0, 1, 2, \dots
$$

**Why is this safe according to Nyquist?**
The Nyquist sampling theorem states that to prevent signal distortion (aliasing), our sampling rate must be at least twice the highest frequency component of our desired signal ($F_{\text{max}}$):

$$
F_{s,\text{out}} \ge 2 \cdot F_{\text{max}}
$$

Because our previous FIR filter already removed all frequencies above $5\text{ MHz}$, dropping the sampling rate to $10\text{ MHz}$ ($2 \times 5\text{ MHz}$) perfectly preserves all original information without losing data quality.


## 5. Expetation vs Result

* **What to Expect:** Instead of a smooth continuous curve that shifts every single clock cycle, `o_decimated_data` will look like a **staircase wave**. The signal holds flat for 10 clock ticks, steps up or down to the next value, and holds flat again. Meanwhile, `o_data_valid` should look like a periodic train of single-width pulses spaced 10 clock cycles apart.
* **Verification Against Results:** In the simulation plots, `o_decimated_data` steps along the baseband wave shape every 10 clock cycles while `o_data_valid` blinks ON precisely every 10th cycle, confirming $10\times$ decimation.



# Top-Level DDC (`ddc_top.sv`)

## 1. What Does This File Do?

The `ddc_top.sv` file acts as the **master blueprint or system supervisor**. It brings together all four individual blocks (`dds.sv`, `mixer.v`, `fir_filter.sv`, and `decimator_b.sv`) and wires them in sequence. Its main role is to take the high-speed, high-frequency signal coming from the radio antenna (or ADC) and orchestrate the full Digital Down Conversion process to output a clean, low-speed baseband signal ready for processing.


## 2. Inputs & Outputs Overview

| Signal Name | Input or Output? | Bit Size | Simple Meaning & Purpose |
| --- | --- | --- | --- |
| `clk` | Input | 1 bit | The main system heartbeat clock running at $100\text{ MHz}$. |
| `rst_n` | Input | 1 bit | Active-low reset button to clear the whole system. |
| `i_if_signal` | Input | 12 bits | The raw incoming Intermediate Frequency (IF) signal coming from the ADC. |
| `ftw` | Input | 32 bits | Frequency Tuning Word passed directly to the internal DDS. |
| `o_i_data` | Output | 38 bits | **Final In-Phase ($I$) Baseband Output:** Downsampled and filtered. |
| `o_q_data` | Output | 38 bits | **Final Quadrature ($Q$) Baseband Output:** Downsampled and filtered. |
| `o_data_valid` | Output | 1 bit | Flag indicating when a new valid output sample is ready ($10\text{ MSPS}$). |


## 3. How the Input Becomes the Output (Step-by-Step)

1. **Carrier Wave Generation (`dds.sv`):** The top level passes `clk`, `rst_n`, and `ftw` into the DDS module to continuously generate matching $20\text{ MHz}$ sine and cosine reference waves (`dds_sin`, `dds_cos`).
2. **Frequency Mixing (`mixer.v`):** The input `i_if_signal` is multiplied by `dds_cos` and `dds_sin` to create raw $I$ and $Q$ channels (`i_mix`, `q_mix`).
3. **Filtering (`fir_filter.sv`):** Two identical FIR filters receive `i_mix` and `q_mix`, removing the double-frequency ripple ($40\text{ MHz}$) and outputting smooth, low-pass baseband signals (`i_fir`, `q_fir`).
4. **Decimation (`decimator_b.sv`):** Two polyphase decimator modules take `i_fir` and `q_fir`, slowing down the rate from $100\text{ MSPS}$ to $10\text{ MSPS}$.
5. **Final Delivery:** The downsampled signals exit the system as `o_i_data` and `o_q_data` every time `o_data_valid` blinks HIGH.


## 4. Mathematical Proofs: System-Wide Signal Transformation

**How does the entire chain transform the input math into the final output?**
Let the incoming raw signal be a passband carrier at frequency $\omega_c$:

$$
\text{i\\_if\\_signal}(t) = s(t) \cdot \cos(\omega_c t + \phi(t))
$$

**Step 1: Quadrature Multiplication (Mixer)**
Multiplying by internal cosine and sine waves creates two parallel pathways:

$$
\text{i\\_mix} = s(t)\cos(\omega_c t + \phi(t)) \cdot \cos(\omega_c t) = \frac{1}{2}s(t)\cos(\phi(t)) + \frac{1}{2}s(t)\cos(2\omega_c t + \phi(t))
$$

$$
\text{q\\_mix} = s(t)\cos(\omega_c t + \phi(t)) \cdot \sin(\omega_c t) = \frac{1}{2}s(t)\sin(2\omega_c t + \phi(t)) - \frac{1}{2}s(t)\sin(\phi(t))
$$

**Step 2: Low-Pass Filtering (FIR Filter)**
The LPF eliminates the high-frequency $2\omega_c$ terms completely:

$$
\text{i\\_fir} = \text{LPF} \left\\{ \text{i\\_mix} \right\\} = \frac{1}{2}s(t)\cos(\phi(t))
$$

$$
\text{q\\_fir} = \text{LPF} \left\\{ \text{q\\_mix} \right\\} = -\frac{1}{2}s(t)\sin(\phi(t))
$$

**Step 3: Downsampling (Decimator)**
The decimator keeps 1 out of every 10 samples ($M=10$), maintaining signal accuracy while cutting down data throughput:

$$
\text{o\\_i\\_data}[m] = \text{i\\_fir}[10m] = \frac{1}{2}s(10m T_s)\cos(\phi(10m T_s))
$$

$$
\text{o\\_q\\_data}[m] = \text{q\\_fir}[10m] = -\frac{1}{2}s(10m T_s)\sin(\phi(10m T_s))
$$


## 5. Expetation vs Result

* **What to Expect:** The top-level outputs `o_i_data` and `o_q_data` should look like clean, stair-stepped baseband waves updating once every 10 clock cycles. All high-frequency noise from the original input signal should be filtered out. The `o_data_valid` strobe should regularly pulse ON every 10th clock tick.
* **Verification Against Results:** In the full system simulation, `o_i_data` and `o_q_data` cleanly trace out low-frequency sine and cosine envelopes in stair-step fashion, with `o_data_valid` firing every 10 clock cycles, confirming the top-level module is integrated properly.


## 6. Verification & Testbench (`ddc_top_tb`)
The `ddc_top_tb` module serves as the simulation environment to verify top-level DDC functional accuracy. It generates real-time synthetic input signals, applies pre-computed MATLAB filter coefficients, and logs output data for external analysis.

### Key Features & Test Setup
* **Clock & Stimulus Generation:** Generates a $100\text{ MHz}$ master system clock (`clk`) and constructs a quantized 12-bit input signal (`i_if_signal`) combining a target carrier wave ($19\text{ MHz}$) and an interference tone ($35\text{ MHz}$).
* **MATLAB Filter Coefficients:** The 33-tap FIR filter coefficients (`fir_coeffs`) and 23-tap Decimator filter coefficients (`deci_coeffs`) were designed and generated using **MATLAB's `filterDesigner`** to ensure sharp out-of-band rejection.
* **Data Logging & Python Post-Processing:** Writes decimated $I/Q$ baseband outputs (`o_i_data`, `o_q_data`) to `ddc_iq_output.txt` on every `o_data_valid` strobe pulse for downstream Python FFT and spectral verification.



# Final Result

![final_wave_result.png](<vx_images/final_wave_result.png>)

## Signal Trace Breakdown (Top to Bottom)

1. **`clk` & `rst_n`:** System clock ($100\text{ MHz}$) and active-low system reset.
2. **`dds_sin` & `dds_cos`:** Generated $20\text{ MHz}$ quadrature reference carriers from `dds.sv`.
3. **`adc_data`:** High-speed, high-frequency input passband signal.
4. **`i_out` & `q_out`:** Mixer output signals showing the expected double-frequency ripple riding on top of the slow baseband envelopes.
5. **$I$-Channel Pipeline (`i_data` $\rightarrow$ `o_data` $\rightarrow$ `o_decimated_data`):**
    * `i_data`: Raw mixer output fed into the FIR filter.
    * `o_data`: FIR filter output showing a clean, smooth low-frequency sine wave with all high-frequency ripple stripped away.
    * `o_decimated_data`: Final downsampled $I$-channel baseband signal updating in $10$-clock-cycle stair-steps ($10\text{ MSPS}$).
6. **$Q$-Channel Pipeline (`i_data` $\rightarrow$ `o_data` $\rightarrow$ `o_decimated_data`):**
    * Identical low-pass filtering and decimation process applied to the Quadrature branch, producing the final stair-stepped $Q$-channel baseband output.


## System Verification

The waveform trace confirms the full hardware design functions as intended:

* **Mixing:** The high-frequency input is successfully split into $I/Q$ channels with visible $2\omega_c$ ripples.
* **Filtering:** The FIR filter completely eliminates the high-frequency content, outputting clean, continuous baseband curves.
* **Decimation:** The polyphase decimator reduces the rate by $10\times$, producing holding stair-step outputs that update every 10 clock cycles while preserving the underlying baseband envelope.



# Future work
- **Trim unnecessary bits:** Oversized the bit limits in several places to guarantee plenty of room, but this can be cleaned up and trimmed down to save resources.
- **Reduce DDS Memory:** Save look-up table space by storing only 1/4 of the wave period and using symmetry to generate the rest.



---

* What does each file do?
* What are the inputs and outputs? 
* What is their meaning/purpose?
* Why are they like that? Use equation to prove.
* Should they look like that? Why or why not? 
* Show the steps of how you got the output from input.

---

 