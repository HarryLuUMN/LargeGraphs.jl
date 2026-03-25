# Validation

This page records the current black-box notebook smoke-check status for the
main user-facing workflows.

## Latest smoke check

Date:
- March 25, 2026

Command approach:
- executed notebooks with `nbclient`
- used the available local kernel `julia-1.12`
- executed from the repository root so the notebooks saw the checked-out project

Notebooks checked:

- `examples/demo_staged_pipeline.ipynb`
- `examples/demo_notebook.ipynb`
- `examples/demo_networklayout_layouts.ipynb`
- `examples/demo_graphsjl.ipynb`

Result:

- all four notebooks executed successfully in the smoke-check harness

## Notes From Validation

- The checked notebooks currently declare a `julia-1.9` kernelspec in notebook metadata, while the local validation environment used `julia-1.12`.
- `nbformat` emitted `MissingIDFieldWarning` warnings because some notebook cells do not yet have explicit cell ids.

These did not block notebook execution in the current environment, but they are
worth cleaning up before a wider alpha rollout to reduce friction for external
users and tooling.
