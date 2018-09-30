build:
	@elm make src/Main.elm --output public/index.html --optimize

deploy:
	@firebase deploy