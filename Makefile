.PHONY: show-refs

show-refs:
	@echo "HEAD → $$(git symbolic-ref HEAD)"
	@git for-each-ref --format="%(refname) → %(objectname:short) (%(contents:subject))" refs/heads refs/remotes

