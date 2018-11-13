import React from 'react';

const mazeFile = 'python-generated-maze.txt';
const solutionFile = 'solution.txt';
const tick = 200; // ms
const jump = 2; // steps/tick
const separator = ' ';

export default class App extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            ready: false,
            counter: 2,
            mazeSize: { x: 0, y: 0 },
            end: { x: 0, y: 0 },
            size: 0,
            maze: [],
            start: {},
        };
    }

    componentWillMount() {
        this.readMaze(mazeFile);
    }

    readMaze = (file) => {
        var rawFile = new XMLHttpRequest();
        rawFile.open("GET", file, false);
        rawFile.onreadystatechange = () => {
            if (rawFile.readyState === 4) {
                if (rawFile.status === 200 || rawFile.status === 0) {
                    const maze = [];
                    let size = 0;
                    let mazeSize = {};
                    let start = {};
                    let end = {};
                    rawFile.responseText.split("\n").forEach((line, index) => {
                        let [x, y] = line.split(separator);
                        x = parseInt(x, 10);
                        y = parseInt(y, 10);
                        if (index === 0) {
                            const _x = window.innerWidth / x;
                            const _y = window.innerHeight / y;
                            size = _x;
                            if (_y < _x) size = _y;
                            mazeSize = { x, y };
                        }
                        else if (index === 1) start = { x, y };
                        else if (index === 2) end = { x, y };
                        else if (line) maze.push(line.split(separator).map((string) => {
                            const value = parseInt(string, 10);
                            return { value, seen: false };
                        }));
                    });
                    // Agregamos el end
                    maze[end.y][end.x].end = true;
                    this.setState({ maze, mazeSize, size, start, end }, () => {
                        this.readSolution(solutionFile);
                    });
                }
            }
        };
        rawFile.send(null);
    };

    readSolution = (file) => {
        var rawFile = new XMLHttpRequest();
        rawFile.open("GET", file, false);
        rawFile.onreadystatechange = () => {
            if (rawFile.readyState === 4) {
                if (rawFile.status === 200 || rawFile.status === 0) {
                    const newMaze = JSON.parse(JSON.stringify(this.state.maze));
                    let { x, y } = this.state.start;
                    let counter = 2;
                    newMaze[y][x].step = counter;
                    newMaze[y][x].solution = true;

                    const _possibleNeighbours = this.getPossibleNeighbours(y, x);
                    _possibleNeighbours.forEach(({ x, y }) => {
                        newMaze[y][x].step = counter;
                    });

                    rawFile.responseText.split("\n").reverse().forEach((line) => {
                        if (line) {
                            let [x, y] = line.split("-");
                            x = parseInt(x, 10);
                            y = parseInt(y, 10);
                            counter += 1;
                            newMaze[y][x].step = counter;
                            newMaze[y][x].solution = true;
                            const possibleNeighbours = this.getPossibleNeighbours(y, x);
                            possibleNeighbours.forEach(({ x, y }) => {
                                if (!newMaze[y][x].step) newMaze[y][x].step = counter;
                            });
                        }
                    });
                    this.setState({ solutionLength: counter, maze: newMaze, ready: true }, () => this.startInterval());
                }
            }
        };
        rawFile.send(null);
    };

    getPossibleNeighbours = (y, x) => {
        const { mazeSize } = this.state;
        const checkX = [0];
        const checkY = [0];
        if (x > 0) checkX.push(-1);
        if (x < mazeSize.x - 1) checkX.push(1);
        if (y > 0) checkY.push(-1);
        if (y < mazeSize.y - 1) checkY.push(1);
        checkX.sort();
        checkY.sort();
        const neighbours = [];
        checkY.forEach((_y) => {
            checkX.forEach((_x) => neighbours.push({ y: y + _y, x: x + _x }));
        });
        console.log({ x, y, neighbours });
        return neighbours;
    }

    startInterval = () => {
        this.interval = setInterval(() => {
            let { counter } = this.state;
            this.setState({ counter: counter + jump });
            if (counter >= this.state.solutionLength - 1) this.cancelInterval();
        }, tick);
    }

    cancelInterval = () => {
        clearInterval(this.interval);
        const { x, y } = this.state.mazeSize;
        const newMaze = JSON.parse(JSON.stringify(this.state.maze));

        // Segundos después de terminar de recorrer el maze, mostramos todo el maze
        setTimeout(() => {
            for (let i = 0; i < y; i += 1) {
                for (let j = 0; j < x; j += 1) {
                    newMaze[i][j].seen = true;
                }
            }
            this.setState({ maze: newMaze });
        }, 3000);
    }


    renderMaze() {
        const { counter, size, maze } = this.state;
        return maze.map((row, y) => {
            return (
                <div style={{ display: 'flex', flexDirection: 'row' }}>
                    {row.map((square, x) => {
                        if (square.solution) {
                            if (square.step === counter) return <div style={{ height: size, width: size, backgroundColor: 'red' }} />;
                            if (square.step < counter) return <div style={{ height: size, width: size, backgroundColor: 'blue' }} />;
                            if (square.end) return <div style={{ height: size, width: size, backgroundColor: 'purple' }} />;
                            if (square.step === counter + 1) {
                                if (square.value === 0) return <div style={{ height: size, width: size, backgroundColor: 'yellow' }} />;
                                if (square.value === 1) return <div style={{ height: size, width: size, backgroundColor: 'brown' }} />;
                            }
                            return <div style={{ height: size, width: size, backgroundColor: 'white' }} />;
                        }
                        if (square.step === counter) {
                            if (square.value === 0) return <div style={{ height: size, width: size, backgroundColor: 'yellow' }} />;
                            if (square.value === 1) return <div style={{ height: size, width: size, backgroundColor: 'brown' }} />;
                        }
                        else if (square.step <= counter) {
                            if (square.value === 0) return <div style={{ height: size, width: size, backgroundColor: 'yellow' }} />;
                            if (square.value === 1) return <div style={{ height: size, width: size, backgroundColor: 'brown' }} />;
                        }
                        else if (square.seen) {
                            if (square.value === 0) return <div style={{ height: size, width: size, backgroundColor: 'yellow' }} />;
                            if (square.value === 1) return <div style={{ height: size, width: size, backgroundColor: 'brown' }} />;
                        }
                        return <div style={{ height: size, width: size, backgroundColor: 'white' }} />;
                    })}
                </div>
            );
        });
    }

    render() {
        console.log(this.state);
        return (
            <div>
                {this.state.ready ? this.renderMaze() : null}
            </div>
        );
    }
}
