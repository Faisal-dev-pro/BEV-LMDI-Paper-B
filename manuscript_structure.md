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
