// skill-check (bdk-skill-kit) rules for the capitan skill: every generic rule
// at error, in the claude-code profile (the skill uses ${CLAUDE_SKILL_DIR}).
export default {
  targets: [{ kind: "skills", dirs: ["skills"] }],
  rules: {
    "description-front-loaded": "error",
    "reasoning-prompts": "error",
    layout: ["error", { allowed: ["references", "scripts"] }],
  },
};
