#include "common.h"
#include <math.h>
#include <iostream>
#include <fstream>
#include <vector>
#include <algorithm>
#include <map>

using namespace std;

//Estructura de nodo
struct Node {
    short x;
    short y;
    short cost;
    float heuristic;
    float score;

    Node() {}

    Node(short x_, short y_, float heuristic_, short cost_) {
        x = x_;
        y = y_;
        heuristic = heuristic_;
        cost = cost_;
        score = heuristic_ + cost_;
    }

    void setNode(short x_, short y_, float heuristic_, short cost_) {
        x = x_;
        y = y_;
        heuristic = heuristic_;
        cost = cost_;
        score = heuristic_ + cost_;
    }

    // Le pasamos un nodo y lo copia a sí
    void copyNode(Node toCopy) {
        x = toCopy.x;
        y = toCopy.y;
        heuristic = toCopy.heuristic;
        cost = toCopy.cost;
        score = toCopy.score;
    }

    void printMe() {
        cout << endl << "x: " << x << endl;
        cout << "y: " << y << endl;
        cout << "heuristic: " << heuristic << endl;
        cout << "cost: " << cost << endl;
        cout << "score: " << score << endl;
    }

    void updateCost(short cost_) {
        cost = cost_;
        score = heuristic + cost_;
    }
};

//Estructura de matriz (maze)
struct Matrix {
    short rows;
    short cols;
    vector<short> data;

    Matrix(short rows_, short cols_):rows(rows_), cols(cols_), data(rows*cols) { }

    short & operator()(size_t row, size_t col) {
        return data[row*cols+col];
    } 

    short operator()(size_t row, size_t col) const {
        return data[row*cols+col];
    } 
};

// Funcion para calcular heuristica de la matriz
__global__ void calcHeuristicOnGPU(float *heuristicMat, short rows, short cols, short finalX, short finalY) {
    //Codigo de clase
    unsigned int ix = threadIdx.x + blockIdx.x * blockDim.x;
    unsigned int iy = threadIdx.y + blockIdx.y * blockDim.y;

    if (ix < cols && iy < rows) {
        for(int i = 0; i < rows; i++) {
            // float distance = sqrt(pow(finalX - x, 2) + pow(finalY - y, 2));
            heuristicMat[iy*cols+ix] = sqrt(pow(finalX - ix, 2) + pow(finalY - iy, 2));
            cout << "x: " << ix << " y: " << iy << "heuristic: " << heuristicMat[iy*cols+ix] << endl;
        }
    }
}

//Funcion para hacer el sort
bool sortQueue (Node a, Node b) { return (a.score < b.score); }

string findPath(Node currentNode, map<string, string> &cameFrom) {
    string key = to_string(currentNode.x) + "-" + to_string(currentNode.y);
    string value = cameFrom[key];
    string path = key + "\n";

    while (value != "START") {
        path += value + "\n";
        key = value;
        value = cameFrom[key];
    }
    return path;
}

short isInSet(Node node, vector<Node> &set) {
    for (int i = 0; i < set.size(); i++) {
        if (node.x == set[i].x && node.y == set[i].y) return i;
    }
    return -1;
}

void checkNeighbour(vector<Node> &tempNodes, Matrix maze, short x, short y, short finalX, short finalY, short cost) {
    float distance = sqrt(pow(finalX - x, 2) + pow(finalY - y, 2));
    if (maze(y, x) != 1) {
        tempNodes.push_back(*new Node(x, y, distance, cost));
    }
}

void expandNode(Node currentNode, vector<Node> &openSet, vector<Node> &closedSet, map<string, string> &cameFrom, Matrix maze, short finalX, short finalY) {
    vector<Node> tempNodes;
    short x = currentNode.x;
    short y = currentNode.y;
    short cost = currentNode.cost + 1;

    // Left
    short _x = x - 1;
    short _y = y;
    checkNeighbour(tempNodes, maze, _x, _y, finalX, finalY, cost);
    // Right
    _x = x + 1;
    checkNeighbour(tempNodes, maze, _x, _y, finalX, finalY, cost);
    // Up
    _x = x;
    _y = y - 1;
    checkNeighbour(tempNodes, maze, _x, _y, finalX, finalY, cost);
    // Down
    _y = y + 1;
    checkNeighbour(tempNodes, maze, _x, _y, finalX, finalY, cost);

    // Checamos cada vecino
    for (int i = 0; i < tempNodes.size(); i++) {
        // Si está en el closed set, no hacemos nada con el nodo
        if (isInSet(tempNodes[i], closedSet) > -1) continue;

        short index = isInSet(tempNodes[i], openSet);
        if (index == -1) { // Si no está en openSet lo metemos a openSet
            openSet.push_back(tempNodes[i]);
        } else { // si sí está en openSet, checamos si llegamos con mejor score y lo actualizamos
            if (tempNodes[i].score >= currentNode.score) continue;
            openSet[index].updateCost(tempNodes[i].cost);
        }

        string key = to_string(tempNodes[i].x) + "-" + to_string(tempNodes[i].y);
        string value = to_string(x) + "-" + to_string(y);
        cameFrom[key] = value;
    }
}

void aStarSearch(Matrix maze, short initialX, short initialY, short finalX, short finalY) {
    vector<Node> closedSet; // Set of nodes already evaluated

    //Creamos el nodo inicial
    float heuristic = sqrt(pow(finalX - initialX, 2) + pow(finalY - initialY, 2));
    Node initialNode(initialX, initialY, heuristic, 0);

    // The set of currently discovered nodes that are not evaluated yet.
    // Initially, only the start node is known.
    vector<Node> openSet;
    openSet.push_back(initialNode);

    // For each node, which node it can most efficiently be reached from.
    // If a node can be reached from many nodes, cameFrom will eventually contain the
    // most efficient previous step.
    // cameFrom := an empty map
    // el key es current y el value es parent
    map<string, string> cameFrom;
    string key = to_string(initialNode.x) + "-" + to_string(initialNode.y);
    cameFrom[key] = "START";

    bool foundSoultion = false;
    while(!openSet.empty()) {
        // Sorteamos los nodos dependiendo del score
        sort(openSet.begin(), openSet.end(), sortQueue);
        Node currentNode = openSet.front();

        // Checamos si llegamos al goal
        if (currentNode.x == finalX && currentNode.y == finalY) {
            cout << "solution found" << endl;
            foundSoultion = true;
            ofstream myfile;
            myfile.open ("public/solution.txt");
            myfile << findPath(currentNode, cameFrom);
            myfile.close();
            break;
        }

        move(openSet.begin(), openSet.begin() + 1, back_inserter(closedSet));
        openSet.erase(openSet.begin());
        expandNode(currentNode, openSet, closedSet, cameFrom, maze, finalX, finalY);
    }
    cout << "End of Search" << endl;
}

int main(int argc, char * argv[]) {
    //Tenemos por default el nombre del txt
    char * mazeText = "public/python-generated-maze.txt";

    // Si nos dieron los file names
    if(argc == 2) mazeText = argv[1];

    // Abrimos el file
    FILE* file_ptr = fopen(mazeText, "r");
    
    if(file_ptr == NULL) {
        cout << "ERROR : Unable to open file " << endl;
        exit(EXIT_FAILURE);
    }

    // Inicializamos variables
    short rows, cols, initialX, initialY, finalX, finalY;
    fscanf(file_ptr, "%hu %hu %hu %hu %hu %hu", &rows, &cols, &initialX, &initialY, &finalX, &finalY);

    //Iteramos a traves de la matriz para poner los valores
    Matrix maze(rows, cols);
    for(int i = 0; i < maze.rows; i++) {
        for(int j = 0; j < maze.cols; j++) {
            fscanf(file_ptr, "%hu", &maze(i, j));
        }
    }

    //COSAS DE CUDA -------------------------------------------
    // set up device
    int dev = 0;
    cudaDeviceProp deviceProp;
    SAFE_CALL(cudaGetDeviceProperties(&deviceProp, dev), "Error device prop");
    printf("Using Device %d: %s\n", dev, deviceProp.name);
    SAFE_CALL(cudaSetDevice(dev), "Error setting device");

    //Bytes
    short nxy = rows * cols;
    float nBytes = nxy * sizeof(float);

    //MALLOC para host matrix
    float *heuristicMatHost;
    heuristicMatHost = (float *)malloc(nBytes);
    
    //Memset del host matrix
    memset(heuristicMatHost, 0, nBytes);

    // Malloc and copy memory to device
    float *heuristicMat;
    SAFE_CALL(cudaMalloc((void **)&heuristicMat, nBytes), "Error allocating heuristicMat");
    // SAFE_CALL(cudaMemcpy(heuristicMat, heuristicMatHost, nBytes, cudaMemcpyHostToDevice), "Error copying Heuristic Mat to Device");

    // invoke kernel at host side
    int dimx = 16;
    int dimy = 16;
    dim3 block(dimx, dimy);
    dim3 grid((cols + block.x - 1) / block.x, (rows + block.y - 1) / block.y);

    // Mandamos a llamar a hacer la matriz
    calcHeuristicOnGPU<<<grid, block>>>(heuristicMat, cols, rows, finalX, finalY);

    // SAFE_CALL kernel error
    SAFE_CALL(cudaGetLastError(), "Error with last error");

    // copy kernel result back to host side
    SAFE_CALL(cudaMemcpy(heuristicMatHost, heuristicMat, nBytes, cudaMemcpyDeviceToHost), "Error copying heuristic back to host");

    // aStarSearch(maze, initialX, initialY, finalX, finalY, heuristicMatHost);

    // free device global memory
    SAFE_CALL(cudaFree(heuristicMat), "Error freeing memory");
    
    // free host memory
    free(heuristicMatHost);

    // reset device
    SAFE_CALL(cudaDeviceReset(), "Error reseting");

    return 0;
}