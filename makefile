check-uv:
	@if ! command -v uv &> /dev/null; then \
		echo "uv could not be found, installing..."; \
		curl -LsSf https://astral.sh/uv/install.sh | sh \
	else \
		echo "uv is already installed."; \
	fi


setup: check-uv
	@uv sync --group dev --group airflow-compiler
	@pre-commit install

.PHONY: build
build:
	@uv build && uv pip install dist/pipelines-0.1.0-py3-none-any.whl

test: setup build
	@uv run pytest .
