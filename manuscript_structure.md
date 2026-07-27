# Applied Energy Manuscript Structure Guide

**Based on:** Two published Applied Energy papers (2023, 2025)
**Purpose:** Writing reference for Paper B (BEV LMDI Decomposition)
**Date:** 24 July 2026

---

## 1. Title Construction

Applied Energy titles are descriptive and front-load the contribution. They follow one of two patterns.

**Pattern A: Topic + colon + scope qualifier**
- "Optimal sizing of renewable energy storage: A techno-economic analysis of hydrogen, battery and hybrid systems considering degradation and seasonal storage"

**Pattern B: Direct descriptive (no colon)**
- "Research progress on the structure design of nano-silicon anode for high-energy lithium-ion battery"

For Paper B, Pattern A fits best. The main contribution comes first, then the scope narrows after the colon.

**Useful constructions:**
- "A [method] analysis of [subject] considering [key factors]"
- "[Method]-based [analysis type] for [application domain]"
- "[Topic]: A comparative study of [variant A], [variant B] and [variant C]"

---

## 2. Abstract

Applied Energy abstracts run 200-300 words. They follow a strict four-part sequence. No citations. No equation numbers. No figure references.

**Part 1: Context and motivation (1-2 sentences)**
Opens with a general statement about the field need, then narrows to the specific gap.
- "Energy storage is essential to address the intermittent issues of renewable energy systems, thereby enhancing system stability and reliability."
- "With the rapid development of electric vehicles and other electronic devices, there is an increasing demand for high energy density batteries..."

**Part 2: What this paper does (2-3 sentences)**
Uses present tense. States the method and scope directly.
- "This paper presents the design and operation optimisation of..."
- "This review provides a detailed overview of advancements in..."
- "The study examines a real-world case study, which is..."

**Part 3: Key results (3-5 sentences)**
Uses present tense or simple past. Gives specific numbers where possible.
- "The modelling results show that..."
- "When comparing battery-only and hydrogen-only systems, battery systems perform better than hydrogen systems in many situations, with a higher self-sufficient ratio and net present value."
- "However, if there is high seasonal variation and a high requirement for using renewable energy (the penetration of renewable energy is >80%), using hydrogen for energy storage is more beneficial."

**Part 4: Broader implication (1 sentence)**
- "This study also shows that storing hydrogen in a long-term strategy can..."
- "Finally, the future development trends and prospects for the large-scale application of... are discussed."

---

## 3. Section Structure

### 3a. Research Article (Paper 1 model)

1. Introduction
2. Literature review (separate section, not merged into Introduction)
3. System and operational strategies (Methodology)
   - 3.1 Case study description
   - 3.2 System modelling
   - 3.3 Operational strategy
4. Optimisation method and implementation
   - 4.1 Objective function
   - 4.2 Optimisation algorithm
5. Results and discussion
   - 5.1 [First comparison axis]
   - 5.2 [Second comparison axis]
   - 5.3 Sensitivity analysis
6. Conclusion

### 3b. Review Article (Paper 2 model)

1. Introduction
2. [Category 1: e.g. Nanostructured design]
   - 2.1 Sub-type A
   - 2.2 Sub-type B
3. [Category 2: e.g. Shell design]
4. [Category 3: e.g. Pore-structure design]
5. [Category 4: e.g. Surface modification]
6. Summary and reviews

### 3c. Recommended for Paper B (multi-vehicle BEV LMDI)

1. Introduction
2. Literature review
3. Methodology
   - 3.1 Vehicle model and validation
   - 3.2 LMDI decomposition framework
   - 3.3 CRG-derived FW boundary
4. Validation results
   - 4.1 Tesla Model 3
   - 4.2 Chevrolet Bolt EV
5. LMDI decomposition results
   - 5.1 Cross-cycle analysis
   - 5.2 Cross-vehicle comparison
   - 5.3 Gear ratio design implications
6. Discussion
7. Conclusions

---

## 4. Introduction Structure

Applied Energy introductions follow a five-move sequence. Each move is typically one paragraph (sometimes two for moves 2-3).

**Move 1: Establish the field (1 paragraph)**
Opens with a broad, factual statement about the domain. No citations needed for the opening sentence. Subsequent sentences cite foundational work.
- "Renewable energy sources, such as solar, wind, geothermal, and biomass, are believed to be alternative energy sources to fossil fuels, which not only minimise pollution and global warming, but also aid in the development of the economy [9-11]."
- "Fossil fuels are a finite resource that will inevitably be depleted in the foreseeable future, necessitating the search for alternative clean energy sources."

**Move 2: Identify the problem or challenge (1-2 paragraphs)**
Introduces the specific technical challenge. Uses "however" or "although" to pivot.
- "Although RES are rapidly growing, there are challenges associated with their wider adoption."
- "However, there are relatively few articles that systematically summarize the research progress on..."
- "Therefore, there is a need to..."

**Move 3: Review the gap (1-2 paragraphs)**
Briefly summarises what prior work has done, then states what is missing. This is distinct from a full literature review section.
- "Recent years have witnessed a growing research interest in..."
- "Addressing this gap is essential for guiding the development of..."

**Move 4: State contributions (bullet list or numbered list)**
Applied Energy papers commonly use a bullet list to enumerate contributions. This is one of the few places where bullet points appear in the body text.
- "The key contributions are summarised as follows:"
- "The main contributions of this paper include:"

**Move 5: Paper roadmap (1 paragraph)**
A brief section-by-section outline.
- "The remainder of this paper is organised as follows. In Section 2, a comprehensive literature review is presented. Section 3 describes... Section 4 presents... The results and discussion are presented in Section 5. Section 6 draws conclusions."
- "This review systematically summarizes the various structural designs and the functional properties of... in Fig. 1."

---

## 5. Literature Review Patterns

Applied Energy favours a structured literature review with clear categorisation. The review is not a flat list of papers. It groups prior work by theme, method, or scale, and each group gets a paragraph or short subsection.

**Opening the literature review:**
- "Optimal design and operation are key aspects of renewable ESSs and have been the subject of many studies in the literature."
- "A review of optimising BESSs was conducted by Hannan et al. [31] and Khezri et al. [32], covering technologies, optimisation objectives, constraints, approaches, and outstanding issues."

**Summarising a group of studies:**
- "In general, for the optimal design of ESS, the size and type of installed technologies are selected in accordance with the availability of local resources and load needs."
- "These structural designs aim to mitigate the issues of volume expansion, low electron conductivity, and limited ion transport in silicon-based anodes."

**Transitioning between groups:**
- "Similarly, the status of research on optimising HESSs has been reviewed by..."
- "In addition to carbon-based materials, metal/metal compounds can also serve as mediums for..."

**Identifying the gap (closing the review):**
- "However, there are still some limitations in the existing studies."
- "Despite these advancements, comprehensive reviews that summarize the latest research progress and future prospects of... remain scarce."

**Citing multiple papers at once:**
- "...has been reviewed by Eriksson and Gray [23], Xu et al. [33], and Khan et al. [34]."
- "...has gained much attention from researchers [30,31,42-44]."

---

## 6. Methodology Language

### 6a. Introducing the model or framework

- "This paper presents the design and operation optimisation of..."
- "The modelling of PEMEL and PEMFC in this paper is based on a theoretical model by Guinot et al. [30]."
- "In this study, lithium-ion batteries were selected because they provide many advantages over other types of batteries [58,59]."

### 6b. Defining variables and parameters

- "The energy stored in the battery can be calculated using the following equations [6,65]:"
- "The SOC for the HESS is defined as the ratio of the stored hydrogen mass to the size of the storage tank:"
- "In this study, the incremental time interval is 1 h and inverter efficiency is 97%."

### 6c. Justifying assumptions

- "This assumption is based on the PV system model used in previous studies [47,48,50]."
- "In addition, a linear degradation rate of 0.55% per year for PV system output is applied in this study."
- "Based on the experimental result from [64], the initial efficiency of the battery is 95% and then it degrades at a constant rate of 2.9% per year, assuming 300 cycles/year."

### 6d. Describing the simulation or experiment

- "To further demonstrate the robustness and versatility of the optimisation method, another synthetic case is tested for..."
- "To accurately compare the performance of the two optimisation algorithms, each algorithm was run five times to ensure that the results were not biased due to randomness in the optimisation."
- "Readers are encouraged to refer to [30] for further details, including..."

---

## 7. Results and Discussion Language

### 7a. Presenting results

- "The modelling results show that the system in the tropical zone always provides a superior return when compared to..."
- "Fig. 9 shows that the MOMFA outperforms the NSGA-II."
- "It can be seen from Table 5 that the component costs of the ultimate scenario are much lower than those of the current scenario."
- "As illustrated in Fig. 13a, during the off-peak hours of a winter day..."
- "The result reveals that..."

### 7b. Comparing results

- "When comparing battery-only and hydrogen-only systems, battery systems perform better than hydrogen systems in many situations."
- "While the MOMFA has located and densely filled all parts of a single Pareto front, the NSGA-II forms two separate fronts."
- "Comparing the two storage options, battery and hydrogen, it is found that..."

### 7c. Interpreting results (causal reasoning)

- "This is attributed to the complementary combination of hydrogen, which can be used as a long-term energy storage option, and battery, which is utilised as a short-term option."
- "This can be attributed to the reduced output in real-world operating conditions because of factors such as soiling of the panels, wiring losses, shading, and aging."
- "This discrepancy is governed by the starting conditions, which include the initial random set of the algorithm."
- "This superior performance is attributed to the unique structural design."
- "Owing to the synergistic effect between Ni and SiO2, the electrode has a reversible capacity of..."
- "Due to the combined effects of the hollow structure and SEI confinement, the prepared HNCSi exhibited excellent electrochemical performance."

### 7d. Drawing intermediate conclusions

- "This finding is similar to the conclusion from previous studies [2,20]."
- "The modelling results in this study accord closely with previous studies on the role of hydrogen in deep decarbonized energy systems [83-86]."
- "These results highlight the potential of co-doped carbon coatings in enhancing the performance of..."

### 7e. Discussing implications

- "The result shows that the hybrid operation strategy, which combines the conventional strategy with the peak-shaving strategy, achieves the best performance."
- "The results highlighted that not considering degradation can lead to erroneous system sizing and cost estimates."
- "This reveals the potential for further increasing the return of the Hybrid ESS by delaying the replacement time of the components."

---

## 8. Conclusion Structure

Applied Energy conclusions follow a three-part structure. They do not introduce new results or new citations.

**Part 1: Restate the purpose (1-2 sentences)**
- "This paper presents the optimisation study of sizing and operational strategy of a grid-connected PV-hydrogen/battery storage system using the Multi-Objective Modified Firefly Algorithm."
- "In this review, the research progress in the structural design of nano-silicon anodes is presented."

**Part 2: Summarise the key findings (3-6 sentences)**
Each finding is one sentence. Uses past tense or present perfect.
- "By comparing the performance of the MOMFA and NSGA-II, this study has shown the proposed MOMFA is more accurate and robust in the design and operation optimisation of energy storage systems."
- "The result reveals that the superiority of the system located in the tropical climate zone... can be attributed to the abundance of solar resources."
- "The research has also shown that hybrid energy storage systems... have better performance compared to systems with only battery or hydrogen."

**Part 3: Future work and limitations (2-4 sentences)**
- "Taken together, the results and findings of this study can support researchers and engineers in developing storage systems for renewable energy."
- "These findings also provide the following insights for future research."
- "Firstly, even though the sensitivity analysis shows that some economic parameters can significantly impact the prediction performance of the systems..."
- "Thus, an uncertainty analysis can be further extended to provide a robust and optimal design for the energy system."

---

## 9. Sentence-Level Patterns

### 9a. Hedging Language (softening claims)

Applied Energy papers use measured language. Absolute claims are rare.

- "...are believed to be alternative energy sources..."
- "...is one of the most promising candidate..."
- "...can significantly influence the performance..."
- "...is viable if there is a high seasonal variation..."
- "...will potentially have a lower footprint..."
- "...warrant further investigation."
- "...is expected to focus on..."
- "...making it a promising direction for future development..."

### 9b. Emphasis and Strengthening

- "It is worth mentioning that..."
- "It is important to consider..."
- "It should be noted that..."
- "It is also observed that..."
- "Interestingly, the HESSs perform better than..."
- "As a result, the contribution of... is significantly reduced."

### 9c. Transition Phrases

**Additive:**
- "In addition, combining batteries for intra-day storage with hydrogen energy for seasonal storage is a viable solution..."
- "Furthermore, the hybrid system outperforms battery-only and hydrogen-only systems."
- "Moreover, this approach eliminates the need for..."
- "Additionally, the lithiation potential of silicon is slightly higher than that of graphite..."

**Contrastive:**
- "However, if there is high seasonal variation..."
- "Nonetheless, it is believed that using hydrogen energy storage systems is viable if..."
- "Although RES are rapidly growing, there are challenges associated with..."
- "On the other hand, for the temperate climate..."
- "While GHI and solar output in HCM fluctuate slightly throughout the year, there are large mismatches between..."

**Causal:**
- "Therefore, there is a need to use an energy storage system..."
- "As a result, BESS, HESS, and Hybrid ESS are investigated in this study."
- "Consequently, the design of nanostructures has been extensively explored..."
- "Thus, the OLDS effectively controls the operation of the HESS..."

**Sequential:**
- "Firstly, RES are dependent on geographic location... Secondly, intermittent renewable energy can cause..."
- "In the following section..."
- "Subsequently, heat treatment... was performed."

**Exemplifying:**
- "...such as solar, wind, geothermal, and biomass..."
- "For instance, coating nano-silicon with a carbon layer has been widely investigated."
- "In other words, the optimisation results of the NSGA-II are not consistent and generalised."

### 9d. Signposting Phrases

- "The literature review presented in the following section shows that..."
- "The remainder of this paper is organised as follows."
- "In this section, the accuracy and performance of the proposed MMOFA are compared with..."
- "This section presents a detailed analysis of..."
- "Readers are encouraged to refer to previous studies [16-18] for detailed discussions on..."
- "Readers are encouraged to refer to [30] for further details, including..."

---

## 10. Figure and Table Referencing

### 10a. Introducing a figure

- "Fig. 1 presents the actual load consumption and daily yield..."
- "As shown in Fig. 6, during the sunny months, if the storage stage is greater than..."
- "As illustrated in Fig. 13a, during the off-peak hours of a winter day..."
- "The degradation processes are illustrated in Fig. 15."
- "As can be seen in Fig. 6b, the HESS in the hybrid system follows the OLDS."

### 10b. Introducing a table

- "Table 2 shows the definition and corresponding electricity price."
- "It can be seen from Table 5 that the component costs..."
- "The relevant properties of the materials depicted in Fig. 4 are shown in Table 3."
- "Detailed electrochemical data are summarized in Table 6."

### 10c. Referencing sub-figures

- "In Fig. 14a, as July is the summer in HCM, the hybrid system only utilises PV and BESS."
- "In Fig. 14a and Fig. 14b, the SOCHESS is usually 100%..."
- "Fig. 12b and Fig. 12d" (not "Figs. 12b,d")

### 10d. Cross-referencing within the paper

- "...as presented in detail in Section 4."
- "...which is presented in detail in Section 5."
- "...as shown in Table 3."
- "...similar to the CS." (abbreviation defined earlier)

---

## 11. Equation Presentation

- "The energy stored in the battery can be calculated using the following equations [6,65]:"
- "The SOC for the HESS is defined as the ratio of..."
- "The relationship between current and hydrogen flow rate is described in Eq. (7) [68]:"
- "...can be calculated from Eq. (16) to (18):"
- Equations are numbered sequentially: (1), (2), (3)...
- Variables defined immediately after the equation block using "where" or "Where"

---

## 12. Common Phrases by Function

### 12a. Stating the research gap

- "...have been the subject of many studies in the literature."
- "...has gained much attention from researchers."
- "...remain scarce."
- "...have not been fully explored."
- "There are relatively few articles that systematically summarize..."
- "Addressing this gap is essential for guiding the development of..."

### 12b. Presenting the contribution

- "This paper presents..."
- "A new [method] is proposed to..."
- "The study examines a real-world case study..."
- "To further demonstrate the robustness and versatility of..."
- "This review systematically summarizes..."

### 12c. Describing validation

- "To verify the performance of..."
- "The results are also compared with those obtained using..."
- "Each algorithm was run five times to ensure that the results were not biased due to randomness."
- "The PV and electricity usage in this study were obtained from the actual monitored data."

### 12d. Discussing limitations

- "There are still some limitations in the existing studies."
- "The complex mechanisms underlying... remain relatively unexplored."
- "However, several challenges remain to be addressed, including..."

### 12e. Recommending future work

- "...which warrant further investigation."
- "...is recommended in future studies."
- "...making it a promising direction for future development."
- "These findings also provide the following insights for future research."
- "Future developments are expected to focus on..."

---

## 13. Voice, Tense, and Person

**Voice:** Predominantly passive in methodology and results. Active voice appears in the introduction and discussion for stronger claims.
- Passive: "The case study is examined..." / "The results are compared..."
- Active: "This paper presents..." / "This study also shows..."

**Tense:**
- Present tense: describing what the paper does, general truths, figure descriptions
  - "Fig. 9 shows that..." / "The modelling results show that..."
- Past tense: describing what was done in the study
  - "The MOMFA was used to determine..." / "Each algorithm was run five times..."
- Present perfect: linking past work to the present
  - "This study has shown..." / "Recent years have witnessed..."

**Person:**
- "This paper" or "This study" as the subject (not "we" or "I")
- "The authors" when referring to themselves in third person
- "Readers are encouraged to refer to..." (addressing the reader directly is acceptable in Applied Energy)

---

## 14. Elsevier / Applied Energy Formatting Notes

- British or American spelling is acceptable but must be consistent throughout. Paper 1 uses British ("optimisation", "organised", "utilised"). Paper 2 uses American ("analyzed", "utilizing").
- Abbreviations defined on first use in both the abstract and the main text separately.
- "Fig." abbreviated in running text; "Figure" at the start of a sentence (though Paper 1 uses "Fig." everywhere).
- Tables have titles above. Figures have captions below.
- References use numbered style [1], [2,3], [4-8].
- Keywords listed below the abstract (5-7 keywords typical).
- Highlights section: 3-5 bullet points, each starting with a verb or noun phrase, each one sentence.

---

## 15. Highlights Section

Each highlight is a standalone finding. Maximum 85 characters per highlight (Elsevier rule). Written as sentence fragments or full sentences.

- "The framework optimises the size and energy operation of renewable energy storage."
- "Degradation of components and variation in energy costs over a 25-year time horizon are considered."
- "A comparative study of hydrogen, battery and hybrid storage system is presented in two different climates."

For Paper B, highlights should cover: LMDI methodology (CRG boundary), multi-vehicle scope, quantified design implication, and validation.

---

## 16. Word-Level Preferences

Applied Energy papers avoid colloquial language. Some common replacements:

| Avoid | Use instead |
|-------|-------------|
| big | significant, substantial |
| show | demonstrate, reveal, indicate |
| get | obtain, achieve, attain |
| use | employ, utilise, adopt |
| find out | determine, ascertain |
| look at | examine, investigate, analyse |
| lots of | numerous, a wide range of |
| important | critical, essential, paramount |
| good | superior, excellent, favourable |
| bad | inferior, suboptimal, adverse |
| enough | sufficient, adequate |
| about | approximately, roughly |

---

## 17. Sentence Length and Rhythm

Average sentence length in both papers is 25-35 words. Sentences rarely exceed 45 words. Complex ideas are broken across two sentences rather than compressed into one.

Short declarative sentences appear after complex ones to provide emphasis:
- "This finding is similar to the conclusion from previous studies [2,20]."
- "The OLDS effectively controls the operation of the HESS."
- "This is because..."

Compound sentences use semicolons sparingly. Colons introduce lists or explanations.

---

*Guide compiled from: Le et al., Applied Energy 336 (2023) 120817; Li et al., Applied Energy 390 (2025) 125820.*

---

## 18. Word Budget (Applied Energy target: 6000-8000 words)

Applied Energy research articles typically fall in the 6000-8000 word range. The previous plan targeted 12,000 words, which is too long. The revised allocation below targets approximately 7000 words (body text only, excluding references, figure captions, and table contents).

| Section | Subsections | Words |
|---------|-------------|-------|
| Abstract | (standalone, 4-part structure per Section 2) | 250 |
| 1. Introduction | Five-move sequence per Section 4 | 800 |
| 2. Literature review | LMDI in energy, BEV energy analysis, gap statement | 700 |
| 3. Methodology | 3.1 Vehicle models and validation data (400), 3.2 LMDI-I decomposition framework (500), 3.3 CRG-derived FW boundary as energy accounting boundary (500) | 1400 |
| 4. Validation results | 4.1 Tesla Model 3 (400), 4.2 Chevrolet Bolt EV (400) | 800 |
| 5. LMDI decomposition results | 5.1 Cross-cycle analysis (500), 5.2 Cross-vehicle comparison (500), 5.3 Gear ratio design implications (500) | 1500 |
| 6. Discussion | Three threads: what decomposition reveals, design guideline, cycle assessment implications | 800 |
| 7. Conclusions | Restate purpose, key findings with numbers, future work | 400 |
| Highlights | 5 bullets, max 85 characters each | 50 |
| **Total** | | **~6700** |

The allocation is flexible within the 6000-8000 envelope. If validation or results need more space, compress the literature review. The methodology section carries the most weight because the CRG boundary comparison is the paper's central methods contribution.

**Actual word count (27 Jul 2026):** 7661 words body text (Sections 1-7). Within target.

---

## 18a. Figure Map (12 figures)

All figures numbered to match manuscript order. PDF and PNG files in `results/figures/`.

| Fig | Filename | Title | Section |
|-----|----------|-------|---------|
| 1 | Fig1_powertrain_schematic | Powertrain schematic | 3.1 |
| 2 | Fig2_drive_cycles | Drive cycle speed profiles with FW onset | 3.1 |
| 3 | Fig3_boundary_methods | Torque-speed boundary methods (M1, M2, M3) | 3.3 |
| 4 | Fig4_validation_energy | Validation cumulative energy (Tesla + Bolt) | 4.1 |
| 5 | Fig5_regime_shares | Regime share stacked bars (4 configs x 5 cycles) | 5.1 |
| 6 | Fig6_boundary_sensitivity | Boundary sensitivity bars (82 pp spread) | 5.1 |
| 7 | Fig7_waterfall_UDDS_US06 | LMDI waterfall UDDS to US06 | 5.1 |
| 8 | Fig8_centrepiece | Centrepiece: operating map + dual waterfall | 5.1 |
| 9 | Fig9_sankey | Sankey energy flow (UDDS vs US06) | 5.1 |
| 10 | Fig10_cross_vehicle | Cross-vehicle structural/intensity bars | 5.2 |
| 11 | Fig11_cross_gear | Cross-gear LMDI decomposition bars | 5.3 |
| 12 | Fig12_FW_vs_gear | FW distance share vs gear ratio | 5.3 |

---

## 19. Vocabulary Discipline

This paper must read as an energy systems paper that uses a powertrain model, not a motors paper that mentions energy. The previous desk rejection (APEN-D-26-15578) failed because it read as a single-vehicle motors case study. Every framing decision below counters that perception.

**In title, abstract, introduction, and conclusions:**
Use the energy community's words. Say "operating regime" first, then define MTPA and field weakening as the regimes' physical basis. Say "structural effect" and "intensity effect" (native LMDI vocabulary). Say "energy accounting boundary" when introducing the FW boundary methods.

**In methodology and results:**
Machine terminology (MTPA, field weakening, d-q axes, current reference generator) is permitted because precise technical language is expected. But always introduce these terms through their energy meaning first.

**Never lead a section with control engineering:**
FOC, PI gains, six-step modulation, current loops. All of that is model instrumentation and lives in the methods subsection or supplementary material.

**Avoid in the title:**
IPMSM, field weakening, CRG, FOC, Simulink. The boundary method contribution is stated in the abstract, not the title.

**Key phrase mappings:**

| Motor/control term | Energy framing |
|--------------------|----------------|
| Field-weakening region | High-speed operating regime |
| MTPA region | Base-speed operating regime |
| CRG-derived FW boundary | Regime accounting boundary derived from motor operating trajectory |
| Torque-speed envelope | Operating envelope |
| Regime share S(r) | Structural factor (LMDI) |
| Per-regime Wh/km I(r) | Intensity factor (LMDI) |

Source: AE_Positioning.md (BEV_LMDI_Decomposition/AppliedEnergy_Paper).

---

## 20. AI Phrase Avoidance List

Grammarly AI detection flags common AI-generated phrases. The following were identified during abstract drafting (July 2026) and must be avoided throughout the manuscript. Use the replacement or rephrase entirely.

| Flagged phrase | AI score | Use instead |
|----------------|----------|-------------|
| "and real-world" | 15x | "and on-road" or "and measured" |
| "mechanisms that govern" | 11x | "factors determining" or "factors responsible for" |
| "that capture" | 10x | "representing" or "quantifying" |
| "physical fidelity" | 20x | "physical accuracy" or "representational accuracy" |
| "decomposition reveals" | 13x | restructure sentence to lead with the finding |
| "high-speed operation" | 10x | "field-weakening operation" or "extended-speed operation" |
| "These findings provide" | 70x | "The decomposition offers" or restructure |

**General AI-style constructions to avoid:**

| Pattern | Why flagged | Alternative |
|---------|-------------|-------------|
| "This study demonstrates that..." | Overused AI opener | Lead with the finding directly |
| "It is worth noting that..." | Filler phrase | Delete; state the point |
| "plays a crucial role in" | AI cliche | "determines" or "governs" or specific verb |
| "a comprehensive analysis of" | AI padding | "an analysis of" |
| "provides valuable insights into" | AI cliche | state the insight directly |
| "sheds light on" | AI cliche | "clarifies" or "explains" |
| "it is important to note" | AI filler | delete |
| "in the context of" | overused | "for" or "during" or "under" |
| "a novel approach to" | AI self-promotion | describe what the approach does |
| "the findings suggest that" | 50x+ AI | state the finding as fact if supported |
| "this highlights the importance of" | AI cliche | state why it matters directly |
| "leveraging" | AI buzzword | "using" or "exploiting" |
| "underscore" / "underscores" | AI favourite | "confirms" or "shows" |
| "delves into" | AI cliche | "examines" or "analyses" |
| "landscape" (metaphorical) | AI cliche | avoid entirely |
| "holistic" | AI buzzword | "complete" or "integrated" |
| "paradigm" | overused | avoid or use only if technically precise |
| "multifaceted" | AI favourite | be specific about the facets |
| em dash ( -- ) | AI punctuation | use comma, semicolon, or split sentence |

---

## 21. Author Style Preferences (Faisal Shah Khan)

Observed from editorial passes on Introduction Moves 1-2 (July 2026). Apply throughout the manuscript.

### Word-level preferences

| Draft word/phrase | Faisal's preference | Note |
|-------------------|---------------------|------|
| a substantial share | a considerable part | |
| range and efficiency | range and output | |
| illustrates | highlights | |
| tested | evaluated | |
| procedures | protocols | |
| separates | distinguishes | |
| seldom extends below | rarely examine data below | |
| figure (as in "Wh/km figure") | level | |
| vary over | fluctuate throughout | |
| cycle representativeness | the representativeness of test cycles | prefers "the [noun] of [noun]" over compound noun |
| between (>2 items) | among | grammatically precise |
| in particular | particularly | prefers adverb form |
| is the established framework | is widely recognized as the standard framework | more explicit |
| has been applied extensively | has been extensively applied | adverb before verb |
| at the national and sectoral level | at both national and sectoral levels | "both...and" + plural |
| have examined how the choice of | have investigated how the selection of | "investigated" over "examined", "selection" over "choice" |
| affect | influence | |
| three gaps persist | three significant gaps remain | "significant" added, "remain" over "persist" |
| has not been applied | has not yet been employed | "yet" + "employed" over "applied" |
| the boundary that distinguishes | the delineation between | "delineation" over "boundary that distinguishes" |
| has not been treated as | has not been considered as | "considered" over "treated" |
| materially alters | can substantially affect | "substantially" over "materially", "affect" over "alter" |
| to establish whether | to determine whether | "determine" over "establish" |
| generalise to | are generalizable to | adjective form |
| contrasting design parameters | differing design parameters | "differing" over "contrasting" |
| addresses these gaps | addresses existing limitations | "existing limitations" over "these gaps" |
| The principal contributions are as follows | The primary contributions are outlined below | "outlined below" over "as follows" |
| implemented | applied | prefers "applied" in contribution statements (cf. "employed" for gap statements) |
| separate...into | partition...into | "partition" over "separate" |
| representing the share of | which quantify the proportion of | relative clause with active verb |
| representing per-regime | which measure...within each regime | relative clause, restates "each regime" |
| contrasting motor designs | distinct motor designs | "distinct" over "contrasting" in contribution context |
| of increasing physical realism | each offering progressively greater physical realism | participial with "progressively greater" |
| is shown to alter | alters | direct active verb, drops passive "is shown to" |
| by up to 57 | by as much as 57 | "as much as" over "up to" |
| establishing that | demonstrating that | "demonstrating" over "establishing" |
| constitutes a significant energy accounting decision | is a significant factor in energy accounting | "factor in" over "constitutes...decision" |
| are conducted on | are performed using | "performed" over "conducted", "using" over "on" |
| account for | explain | "explain" over "account for" in results context |
| on three of four cycles evaluated | across three of four evaluated cycles | "across" + adjective before noun |
| enters extended-speed operation at 88 km/h compared with 118 km/h for the Tesla | transitions to extended-speed operation at 88 km/h, whereas the Tesla Model 3 does so at 118 km/h | "transitions to" + "whereas" separate clause |
| because motor design parameters rather than | indicating that motor design parameters, rather than | "indicating that" + comma-set "rather than" |
| determine regime exposure | govern regime exposure | "govern" over "determine" |
| The remainder of this paper is organised as follows | The structure of the paper is as follows | direct, no "remainder" |
| reviews prior work | reviews previous research | "previous research" over "prior work" |
| and on [second topic] | as well as studies on [second topic] | "as well as" over second "and on" |
| describes the methodology | details the methodology | "details" over "describes" |
| reports the validation results | presents validation results | drops article, "presents" over "reports" |
| presents the LMDI results | provides the LMDI results | "provides" over "presents" (variety) |
| discusses the implications | examines the implications | "examines" over "discusses" |
| draws conclusions | concludes the paper | direct verb form |
| captures (for intensity term) | reflects | "reflects" over "captures" for describing what a term does |
| The method has been extensively | This method has been widely | "widely" over "extensively", "This" over "The" |
| through both | using both | "using" over "through" |
| capturing the sensitivity | to represent the sensitivity | infinitive over participial for purpose |
| The influence of X has been quantified by several studies | Several studies have quantified the influence of X | active voice, subject-first |
| for battery electric vehicles specifically | for battery electric vehicles | drop "specifically" |
| These studies confirm | Collectively, these studies confirm | add "Collectively" for paragraph-closing synthesis |
| depends on which regime is active | is determined by the active operating regime | passive, more concise |
| the dominant topology | which are the dominant topology | relative clause with "which are" |
| at the cost of | resulting in | participial over prepositional |
| The speed at which this transition occurs | The transition speed between these regimes | noun phrase over relative clause |
| how much of a given drive cycle falls within | the proportion of a drive cycle spent in | "proportion" over "how much" |
| other loss mechanisms | other loss factors | "factors" over "mechanisms" |
| the structural fact of residing in that regime | the structural effect of regime residence | nominal form |
| Connecting these lines of inquiry | Bridging these research areas | "Bridging" over "Connecting", "research areas" over "lines of inquiry" |
| The present study provides this connection | This study provides such a connection | "such a" over "this" |

### Sentence-level preferences

1. **Split at conjunctions.** Compound sentences joined by "yet" or "but" should be split into two sentences. Use "However," as the pivot opener for the second sentence.

2. **Spell out acronyms in full on first use.** Even well-known acronyms (WLTP, US EPA) must be expanded on first use in the body text, with the abbreviation in parentheses. Separate from the abstract (which has its own first-use expansions).

3. **Participial restructuring.** Prefers participial phrases ("resulting in variations in...") over compound clauses ("and the energy consumed... differs...") when describing consequences within a single sentence.

4. **Explicit definitions over parallel shorthand.** Instead of compressed parallel constructions ("arising from where... and arising from how..."), prefers explicit constructions with "such as" and "which arise from" to define terms on first appearance.

5. **Formal register.** Consistently selects the more formal alternative: "evaluated" over "tested", "protocols" over "procedures", "distinguishes" over "separates", "fluctuate" over "vary."

6. **Adverb placement.** Prefers adverb before the past participle ("extensively applied", "widely recognized") rather than after ("applied extensively", "recognized widely").

7. **"Both...and" with plural.** Uses "at both national and sectoral levels" rather than "at the national and sectoral level."

8. **"Despite these advances" over "However."** For Move 3 gap-statement pivot, prefers "Despite these advances" as a concessive opener rather than a standalone "However" sentence. Note: "However," is still preferred for simple pivots (Move 2 style).

9. **"Not yet been employed" over "not been applied."** Adds "yet" to signal temporal gap (no one has done this so far) and prefers "employed" over "applied" to avoid repeating "applied" (which appears in the preceding LMDI-applications sentences).

10. **"Even though" subordinate clause.** Prefers embedding the consequence within the gap statement ("even though its definition can substantially affect the decomposition results") rather than using a relative clause ("whose definition materially alters the decomposition").

**Safe academic verbs (from published AE papers):**
demonstrates, confirms, identifies, establishes, quantifies, characterises, evaluates, indicates, suggests, attributes, presents, examines, compares, determines, reports, validates, proposes, employs, adopts, investigates

**Test before submission:** Paste each section into Grammarly AI detector. Any phrase flagged above 10x must be rewritten before the section is considered complete.
