# mgds-pipelines-library-src
WIP

## Setup

```bash
make setup
```

## Build

```bash
make build
```

## Test
```bash
make test
```

## Dependency

Managed with uv

```bash
uv add <dependency>
```

### Add dev dependency
```bash
uv add --dev <dependency>
```


### Add compiler specific dependencies
```bash
uv add <dependency> --group=airflow-compiler
```


## Tests

All compiler tests must live in separate  folders because clashing dependencies etc.


## Adding a new compiler

Be sure to add tests to `tests/compilers/<new compiler>`, and add a new entry into `.pre-commit-config.yaml` e.g.
```yaml
      - id: test-<new compiler>
        name: test-<new compiler>
        types: [python]
        entry: uv run pytest
        args:
          - "tests/compilers/<new compiler>"

        language: system
        pass_filenames: false
        always_run: true
```
