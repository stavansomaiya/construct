---
license: apache-2.0
---
# Indian Multilingual Scam Message Dataset

## Overview
This dataset contains 120 realistic SMS and text messages from Indian contexts, labeled as scam or legitimate. It reflects real-world communication patterns across Hindi, Hinglish, and English.

## Features
- 120 high-quality samples
- Multilingual (Hindi, Hinglish, English)
- Real-world inspired scam and legitimate messages
- Includes reasoning for each label
- Covers multiple domains: banking, ecommerce, telecom, utilities, finance, and government

## Dataset Structure

| Column | Description |
|--------|------------|
| message | The SMS or text message |
| label | scam or legit |
| reason | Explanation for classification |
| domain | Application domain (banking, ecommerce, etc.) |
| language | Language used (Hindi, Hinglish, English) |

## Example

| message | label |
|--------|------|
| आपका बैंक खाता सत्यापन लंबित है, कृपया तुरंत अपडेट करें | scam |
| Your OTP is 456789. Do not share it with anyone. | legit |

## Use Cases
- Scam detection systems
- Spam filtering models
- Fraud prevention tools
- Multilingual chatbot safety layers

## Motivation
Fraudulent SMS and phishing attacks are common in India, especially in multilingual and code-mixed formats. This dataset helps build AI systems that can better understand and detect such threats in real-world scenarios.

## Evaluation
This dataset can be evaluated using:
- Classification accuracy
- Precision / Recall / F1-score
- Human validation for realism and correctness
