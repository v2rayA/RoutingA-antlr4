.PHONY: all clean dir g4 go cpp readme

all: clean dir readme g4 go cpp

clean:
	rm -rf build/

dir: clean
	mkdir build/

g4: dir
	cp *.g4 build/

go: g4
	cd build && \
		antlr4 -Dlanguage=Go -o go/routingA/ -package "routingA" routingA.g4 && \
		cd go/routingA/ && \
		go mod init github.com/v2rayA/RoutingA-dist/go/routingA && \
		go mod tidy

cpp: g4
	cd build && \
		antlr4 -Dlanguage=Cpp -o cpp/routingA/ -package "routingA" routingA.g4

readme: dir
	echo "Dist of [RoutingA-antlr4](https://github.com/v2rayA/RoutingA-antlr4)" > README.md
