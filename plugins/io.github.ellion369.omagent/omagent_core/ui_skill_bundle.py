"""The UI/UX skill bundle used by Omagent's agentic design lane."""
from __future__ import annotations

from dataclasses import dataclass


UI_SKILL_BUNDLE_VERSION = "ui-skill-bundle/v1"


@dataclass(frozen=True)
class UiSkillBundle:
    version: str
    primary_skill: str
    supporting_skills: tuple[str, ...]
    motion_skill: str
    component_skill: str
    reviewer_skill: str
    description: str

    def as_dict(self) -> dict[str, object]:
        return {
            "version": self.version,
            "primary_skill": self.primary_skill,
            "supporting_skills": list(self.supporting_skills),
            "motion_skill": self.motion_skill,
            "component_skill": self.component_skill,
            "reviewer_skill": self.reviewer_skill,
            "description": self.description,
        }

    def prompt_directive(self) -> str:
        skills = ", ".join(self.supporting_skills)
        return f"""[OMAGENT UI/UX IMPECCABLE SYSTEM v{self.version}]
Primary design director: {self.primary_skill}.
Required UI/UX skill set: {skills}.

Use this sequence for every agentic UI/UX task:
1. Establish the product brief, audience, task, content, and constraints before styling.
2. Use {self.primary_skill} to choose a deliberate visual world and reject generic defaults.
3. Use {self.component_skill} for tokens, layout, responsive structure, and component composition.
4. Use {self.motion_skill} and interaction-design for purposeful motion, feedback, and state transitions.
5. Render the actual artifact at desktop, tablet, and mobile sizes.
6. Use visual-critique, accessibility-audit, and ce-test-browser to inspect the rendered result.
7. Use impeccable and the independent reviewer skill to perform a final anti-slop audit.

Rules:
- The user's brief is product authority. References are bounded visual evidence, never copied content.
- Do not ship a generic dashboard, generic gradient, repeated card grid, decorative pill spam, or interchangeable hero pattern.
- Every visual decision must support the product task, content hierarchy, or interaction.
- Do not claim a design skill, browser check, accessibility check, or visual review ran unless it actually ran.
- Report the selected concept, applied skill decisions, rendered evidence, findings, and unresolved gaps.
- The controller owns completion; provider prose cannot certify a UI result.
"""


def impeccable_ui_bundle() -> UiSkillBundle:
    return UiSkillBundle(
        version=UI_SKILL_BUNDLE_VERSION,
        primary_skill="impeccable",
        supporting_skills=(
            "web-design-engineer",
            "ui-design",
            "visual-critique",
            "design-systems",
            "color-system",
            "layout-grid",
            "interaction-design",
            "state-machine-ux",
            "form-design",
            "loading-states",
            "accessibility-audit",
            "animate",
            "review-animations",
            "apple-design",
            "find-animation-opportunities",
            "ce-ui-optimize",
            "ce-test-browser",
        ),
        motion_skill="animate",
        component_skill="design-systems",
        reviewer_skill="impeccable",
        description="Impeccable-led product UI/UX: deliberate visual direction, tokenized structure, purposeful interaction, rendered critique, accessibility, and anti-slop verification.",
    )
