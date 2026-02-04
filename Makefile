# Cargar variables de .env si existe
-include .env
export

.PHONY: run run-chrome run-edge run-firefox run-debug run-canvaskit clean build build-web build-web-local serve deploy deps analyze format test devices help

# Puerto por defecto para el servidor de desarrollo
PORT ?= 8080
GITHUB_USER ?=
REPO_NAME ?= youtube-english-songs
BASE_HREF ?= /$(REPO_NAME)/

help: ## Muestra esta ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

run: ## Inicia en Chrome (navegador por defecto)
	flutter run -d chrome

run-chrome: ## Inicia en Chrome con hot reload
	flutter run -d chrome --web-port=$(PORT)

run-edge: ## Inicia en Edge
	flutter run -d edge --web-port=$(PORT)

run-firefox: ## Inicia en Firefox
	flutter run -d web-server --web-port=$(PORT)

run-debug: ## Inicia en Chrome con herramientas de debug
	flutter run -d chrome --web-port=$(PORT) --web-renderer html

run-canvaskit: ## Inicia con renderer CanvasKit (mejor rendimiento gráfico)
	flutter run -d chrome --web-port=$(PORT) --web-renderer canvaskit

deps: ## Instala/actualiza dependencias
	flutter pub get

clean: ## Limpia archivos de build
	flutter clean

build: ## Compila para producción
	flutter build web --release

build-web: ## Compila para producción (GitHub Pages con base-href)
	flutter build web --release --base-href "$(BASE_HREF)" --no-tree-shake-icons

build-web-local: ## Compila para producción (local sin base-href)
	flutter build web --release --no-tree-shake-icons

serve: build-web-local ## Compila y sirve los archivos de producción
	cd build/web && python3 -m http.server $(PORT)

analyze: ## Analiza el código
	flutter analyze

format: ## Formatea el código
	dart format .

test: ## Ejecuta los tests
	flutter test

devices: ## Lista dispositivos/navegadores disponibles
	flutter devices

deploy: build-web ## Publica en GitHub Pages
	@if [ -z "$(GITHUB_USER)" ]; then \
		echo "Define GITHUB_USER. Ejemplo: make deploy GITHUB_USER=tu-usuario"; \
		exit 1; \
	fi
	cd build/web && \
	git init && \
	git add -A && \
	git commit -m "Deploy to GitHub Pages" && \
	git push -f git@github.com:$(GITHUB_USER)/$(REPO_NAME).git main:gh-pages
