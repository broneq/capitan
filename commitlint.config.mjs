// Conventional Commits: release-please derives versions and changelogs from them.
export default {
  extends: ["@commitlint/config-conventional"],
  // No line length limit in body and footer: agents write long explanations there.
  rules: {
    "body-max-line-length": [0],
    "footer-max-line-length": [0],
  },
};
