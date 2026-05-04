.PHONY: submodule-status
submodule-status:
	git submodule status --recursive

.PHONY: submodule-update
submodule-update:
	git submodule update --init --recursive

.PHONY: firmware-build
firmware-build:
	cd firmware/ClusterController && pixi run build-rewrite

.PHONY: firmware-flash
firmware-flash:
	cd firmware/ClusterController && pixi run flash-rewrite

.PHONY: firmware-flash-artifact
firmware-flash-artifact:
	cd firmware/ClusterController && pixi run flash-artifact-rewrite

.PHONY: python-test
python-test:
	cd software/hex_maze_interface_python && pixi run test

.PHONY: desk-verify
desk-verify:
	cd software/hex_maze_interface_python && pixi run verify

.PHONY: desk-smoke
desk-smoke:
	cd software/hex_maze_interface_python && python hardware_smoke_test.py --clusters 10

.PHONY: desk-repeated-home
desk-repeated-home:
	cd software/hex_maze_interface_python && python hardware_repeated_home_test.py --cluster 10 --trial-count 10 --home-repeat-count 5

.PHONY: full-verify
full-verify:
	cd software/hex_maze_interface_python && pixi run verify

.PHONY: full-smoke
full-smoke:
	cd software/hex_maze_interface_python && python hardware_smoke_test.py --clusters 10 11 12 13 14 15 16

.PHONY: full-repeated-home
full-repeated-home:
	cd software/hex_maze_interface_python && for cluster in 10 11 12 13 14 15 16; do python hardware_repeated_home_test.py --cluster $$cluster --trial-count 10 --home-repeat-count 5 || exit $$?; done
