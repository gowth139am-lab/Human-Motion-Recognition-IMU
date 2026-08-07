# Human Motion Recognition Using IMUs (HMR_IMU)

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=gowth139am-lab/Human-Motion-Recognition-IMU)

MathWorks Excellence in Innovation — Project #232

**Author:** Gowtham S, Nagaraju D V, Sharath H G
**Affiliation:** PES University
**Toolchain:** MATLAB Online, Statistics and Machine Learning Toolbox, MATLAB Mobile

---

## 1. Project Overview

This project implements a human activity recognition (HAR) system that classifies six
categories of human motion — **Walking, Walking Upstairs, Walking Downstairs, Sitting,
Standing, Laying** — using accelerometer and gyroscope (IMU) data.

Two things were required by the project brief:

1. Train and evaluate a classifier on IMU data using MATLAB's Machine Learning /
   Deep Learning tooling.
2. Validate the trained classifier using **live sensor data captured on a real phone**
   via the MATLAB Mobile app.

Both requirements are addressed below, including an honest account of what worked,
what didn't, and why.

---

## 2. Dataset

**UCI HAR Dataset** (Human Activity Recognition Using Smartphones), Anguita et al. 2012.

- 30 subjects, waist-mounted Samsung Galaxy S2
- Accelerometer + gyroscope sampled at 50 Hz
- Signal split into fixed 2.56 s windows (128 readings/window, 50% overlap)
- 7,352 training windows / 2,947 test windows
- Split is subject-independent (no overlap between train/test subjects)

Two versions of features were used across this project (see Section 3).

---

## 3. Models Trained

### 3.1 Model A — UCI HAR's original 561 pre-computed features

The dataset ships with 561 hand-engineered time- and frequency-domain features per
window. 36 classifier types were trained and compared in Classification Learner
(trees, discriminants, logistic regression, SVM variants, KNN variants, ensembles,
and neural networks).

**Winner: Cubic SVM**

| Metric | Value |
|---|---|
| Validation accuracy (5-fold CV) | 99.0% |
| **Test accuracy (held-out subjects)** | **94.7%** |
| Model size (compact) | ~12 MB |
| Prediction speed | ~2,600 obs/sec |

Confusion matrix showed the model correctly separates dynamic vs. static activities
almost perfectly; nearly all errors were within-category (e.g. Walking Upstairs
confused with Walking Downstairs, or Sitting confused with Standing) — a well known,
explainable limitation of single-IMU HAR, not a flaw in the pipeline.

### 3.2 Model B — Compact 48-feature set (for MATLAB Mobile compatibility)

UCI HAR's original 561-feature pipeline is not fully reproducible from a live phone
recording (undocumented filtering/FFT steps). A smaller, well-defined 48-feature set
(mean, std, min, max, RMS, skewness, kurtosis, energy — per raw axis, 6 channels) was
computed directly from UCI HAR's raw `Inertial Signals` files, so training and phone
data could be processed identically.

**Winner (by test accuracy, not validation accuracy): Linear SVM**

| Model | Validation Acc. | Test Acc. |
|---|---|---|
| Bagged Trees | 97.9% | 82.2% (overfit) |
| Cubic SVM | 97.5% | 85.2% |
| Quadratic SVM | 97.0% | 86.0% |
| **Linear SVM** | 94.1% | **88.0%** |

Notably, the simplest linear decision boundary generalized best — more complex
kernels and ensembles had higher validation accuracy but overfit to the training
subjects' folds. This is documented explicitly as a finding rather than hidden.

### 3.3 Model C — Orientation-invariant 28-feature set

To rule out phone-mounting orientation as the cause of validation failures (see
Section 4), a third feature set was built using **acceleration/gyroscope magnitude**
(orientation-independent) plus per-axis std/RMS.

**Winner: Quadratic SVM**

| Model | Validation Acc. | Test Acc. |
|---|---|---|
| Bagged Trees | 96.4% | 83.5% |
| Cubic SVM | 96.1% | 86.8% |
| **Quadratic SVM** | 95.8% | **88.5%** |

A verification step is worth documenting: an initial training run in this phase
produced a spurious 99–100% test accuracy across multiple model types. Investigation
(row-count checks, subject-overlap checks, and directly inspecting
`NumObservations` on the trained model object) traced the cause to Classification
Learner's "New Session" dialog having the training and test tables swapped — the
model had been trained on the 2,947-row test set rather than the 7,352-row training
set, so it was being evaluated on data it had already seen. Retraining with the
correct table produced the realistic, reproducible results above. This is reported
here because it reflects a real and easy-to-make mistake in this workflow, and the
verification habit (always checking `predictFcn` output against the true labels in
code, rather than trusting the app's displayed "Accuracy (Test)" alone) is what
caught it.

---

## 4. Real-World Validation via MATLAB Mobile

Per the project brief, the trained classifier was tested against live phone sensor
data, recorded using the MATLAB Mobile app (Acceleration + Angular Velocity logging).

**Recorded activities:** Standing, Sitting, Walking (Walking Upstairs/Downstairs
recorded where accessible). Laying was not recorded live for practical/safety
reasons and was validated only via the dataset's held-out test set.

### 4.1 Pipeline

1. Record with MATLAB Mobile (phone in a fixed, consistent position across all
   recordings)
2. Resample Acceleration (~50 Hz) and Angular Velocity (~12.5 Hz on this device) to
   a common 50 Hz timeline, using `retime`
3. Align to overlapping time range, combine into a 6-channel signal
4. Window into 128-sample (2.56 s) segments with 50% overlap
5. Extract features matching one of the trained models (Section 3.2 / 3.3)
6. Run the trained model's `predictFcn` on the resulting feature windows

### 4.2 Result

The Standing recording (94 windows) was **misclassified as Laying** by both the
48-feature and orientation-invariant models (97.9% and 97.9% of windows
respectively predicted class 6 / LAYING).

### 4.3 Root-Cause Investigation

A systematic diagnosis was performed rather than accepting the failure at face value:

| Hypothesis | Test | Result |
|---|---|---|
| Unit mismatch (m/s² vs. g) | Compared magnitudes | Confirmed — phone reports raw m/s² (~9.8), UCI HAR's `total_acc` is g-normalized (~1.0). Corrected by dividing by 9.81. |
| Orientation mismatch | Compared per-axis gravity dominance | Confirmed — UCI HAR's Standing samples show gravity dominant on the X-axis; the phone recording showed gravity dominant on the Y-axis, indicating a different mounting orientation than the original dataset's waist-mounted, fixed-orientation setup. |
| Orientation-invariant features would fix it | Retrained on magnitude-based features (Model C, Quadratic SVM, 88.5% UCI HAR test accuracy) | Did **not** resolve misclassification — still predicted mostly Laying. |
| Sensor noise / domain gap | Compared magnitude mean & std between phone data and UCI HAR classes | Phone recording's acceleration-magnitude standard deviation (≈0.044) was **3–5× higher** than either UCI HAR Standing (≈0.009) or Laying (≈0.014), despite a similar mean magnitude. This points to a genuine domain gap between the recording device/conditions and the original 2012 Samsung Galaxy S2 dataset collection. |

### 4.4 Conclusion

Unit correction and orientation-invariant features each addressed one real, confirmed
issue, but did not fully close the gap — this is expected and is a **documented,
known limitation of HAR systems trained on one fixed device/collection protocol and
deployed on a different device**. This is a well-recognized open problem in HAR
research (commonly termed the "sensor domain gap" or "cross-device generalization"
problem), not a defect in this implementation.

This finding is reported honestly rather than masked, and is treated as a genuine
result of the project's validation phase.

---

## 5. Summary of Results

| Model | Features | Test Accuracy (UCI HAR) | Phone Validation |
|---|---|---|---|
| Cubic SVM | 561 (UCI HAR original) | **94.7%** | Not directly testable (feature pipeline not reproducible from raw phone signal) |
| Linear SVM | 48 (custom, raw-axis stats) | 88.0% | Misclassified (Standing → Laying) |
| Quadratic SVM | 28 (orientation-invariant, magnitude-based) | 88.5% | Misclassified (Standing → Laying) |

---

## 6. Repository Structure

```
HMD_proj_1/
├── Dataset/          # UCI HAR dataset + extracted feature sets (.mat)
├── Models/           # Trained, exported classifiers (.mat)
├── Results/          # Confusion matrices (.png) and accuracy summaries (.csv)
└── Scripts/          # extractFeatures.m, extractFeaturesInvariant.m,
                       # reloadWorkspace.m, Classification Learner session
```

---

## 7. Limitations & Future Work

- **Cross-device domain gap**: the largest open issue. Future work could apply
  domain adaptation, per-device calibration, or train directly on multi-device data
  to close this gap.
- **Sitting/Standing confusion**: a persistent, mild confusion across all models,
  consistent with published HAR literature — a single waist/pocket-mounted IMU has
  limited ability to distinguish static postures that differ mainly in joint angle
  rather than acceleration signature.
- **Laying not validated live**: for practical/safety reasons; validated only via
  the dataset's held-out test set.
- **Advanced project extensions** (IMU simulation via `imuSensor`, live gesture
  control of MATLAB) were out of scope for this submission but are natural next
  steps.

---

## 8. How to Reproduce

1. Open `Scripts/reloadWorkspace.m` in MATLAB Online — reloads all datasets, feature
   sets, and trained models.
2. Open `Models/bestActivityClassifier.mat` for the primary (561-feature) model, or
   `bestActivityClassifier48.mat` for the phone-compatible model.
3. See `Results/` for saved confusion matrices and accuracy tables.
