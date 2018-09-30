build:
	@elm make src/Main.elm --output public/index.html --optimize

debug:
	@elm make src/Main.elm --output public/index.html

deploy:
	@firebase deploy

clean:
	@rm -rf public