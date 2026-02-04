.PHONY: run run-chrome run-edge run-firefox clean build serve deps help

# Puerto por defecto para el servidor de desarrollo
PORT ?= 8080

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

serve: build ## Compila y sirve los archivos de producción
	cd build/web && python3 -m http.server $(PORT)

analyze: ## Analiza el código
	flutter analyze

test: ## Ejecuta los tests
	flutter test

devices: ## Lista dispositivos/navegadores disponibles
	flutter devices
