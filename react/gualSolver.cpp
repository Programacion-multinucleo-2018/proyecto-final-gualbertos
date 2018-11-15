#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <iostream>
#include <fstream>
#include <vector>
#include <map>
#include <algorithm>
#include <list>

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
    Matrix(short rows_, short cols_):rows(rows_), cols(cols_), data(rows*cols) {

    }
    short & operator()(size_t row, size_t col)
    {
        return data[row*cols+col];
    } 
    short operator()(size_t row, size_t col) const
    {
        return data[row*cols+col];
    } 
};

//Funcion para hacer el sort
bool sortQueue (Node a, Node b) { return (a.score < b.score); }

string findPath(Node currentNode, map<string, string> &cameFrom) {
    //Definicion de string temporal
    string key = to_string(currentNode.x) + "-" + to_string(currentNode.y);
    string value = cameFrom[key];
    string path = key + "\n";

    while (value != "START") {
        path += value + "\n";
        key = value;
        value = cameFrom[key];
    }

    cout << "path:" << endl;
    cout << path << endl;

    return path;
}

short isInSet(Node node, vector<Node> &set) {
    for (int i = 0; i < set.size(); i++) {
        if (node.x == set[i].x && node.y == set[i].y) {
            return i;                        
        }
    }
    return -1;
}

void expandNode(Node currentNode, vector<Node> &openSet, vector<Node> &closedSet, map<string, string> &cameFrom, Matrix maze, short finalX, short finalY) {
    vector<Node> tempNodes;
    short x = currentNode.x;
    short y = currentNode.y;
    short cost = currentNode.cost + 1;
    cout << "current node x:" << x << " y: " << y << endl;
    // Left
    cout << "x: " << x - 1 << " y: " << y << endl;
    cout << maze(y, x - 1) << endl;
    if (maze(y, x - 1) != 1) {
        tempNodes.push_back(*new Node(x - 1, y, sqrt(pow(finalX - x - 1, 2) + pow(finalY - y, 2)), cost));
        // TODO: Aquí se me hace que lo tenemos que meter el score al map de scores
    }
    // Right
    cout << "x: " << x + 1 << " y: " << y << endl;
    cout << maze(y, x + 1) << endl;
    if (maze(y, x + 1) != 1) {
        float distanceFinal = sqrt(pow(finalX - x + 1, 2) + pow(finalY - y, 2));
        Node tempNode (x + 1, y, distanceFinal, cost);
        // expandNodeDir(tempNode);
        // TODO: este pedo no funciona para 3-1 que es un 0
        // tempNodes.push_back(*new Node());
    }
    // Up
    cout << "x: " << x  << " y: " << y - 1 << endl;
    cout << maze(y - 1, x) << endl;
    if (maze(y - 1, x) != 1) {
        float distanceFinal = sqrt(pow(finalX - x, 2) + pow(finalY - y - 1, 2));
        tempNodes.push_back(*new Node(x, y - 1, distanceFinal, cost));
    }
    // Down
    cout << "x: " << x  << " y: " << y + 1 << endl;
    cout << maze(y + 1, x) << endl;
    if (maze(y + 1, x) != 1) {
        float distanceFinal = sqrt(pow(finalX - x, 2) + pow(finalY - y + 1, 2));
        tempNodes.push_back(*new Node(x, y + 1, distanceFinal, cost));
    }
    cout << "endendendendendend\n\n" << endl;

    // Checamos cada vecino
    cout << "temp nodes" << endl;
    for (int i = 0; i < tempNodes.size(); i++) {
        tempNodes[i].printMe();
        // Checamos si está en closedSet
        if (isInSet(tempNodes[i], closedSet) > -1) break;
        short index = isInSet(tempNodes[i], openSet);
        if (index == -1) { // Si no setá en openSet
            openSet.push_back(tempNodes[i]);
        } else {
            if (tempNodes[i].score >= currentNode.score) break;
            string key = to_string(tempNodes[i].x) + "-" + to_string(tempNodes[i].y);
            string value = to_string(x) + "-" + to_string(y);
            cameFrom[key] = value;
            openSet[index].updateCost(tempNodes[i].cost);
        }
    }
    cout << "===========\n\n" << endl;
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
    // el key es el elemento y el value es de donde vino.
    map<string, string> cameFrom;
    string key = to_string(initialNode.x) + "-" + to_string(initialNode.y);
    cameFrom[key] = "START";

    bool foundSoultion = false;
    while(!openSet.empty()) {
        // Sorteamos los nodos dependiendo del score
        sort(openSet.begin(), openSet.end(), sortQueue);
        Node currentNode = openSet.front();
        // cout << currentNode.x << " , " << currentNode.y << endl;

        // Checamos si llegamos al goal
        if (currentNode.x == finalX && currentNode.y == finalY) {
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

    if(argc == 2) { //Si nos dieron los file names
        mazeText = argv[1];
    }

    //Abrimos el file
    FILE* file_ptr = fopen(mazeText, "r");
    
    if(file_ptr == NULL) {
        cout << "ERROR : Unable to open file " << endl;
        exit(EXIT_FAILURE);
    }

    //Inicializamos variables
    short rows, cols, initialX, initialY, finalX, finalY;
    fscanf(file_ptr, "%hu %hu %hu %hu %hu %hu", &rows, &cols, &initialX, &initialY, &finalX, &finalY);

    //Debug print
    // cout << initialX << " , " << initialY << endl;
    // cout << finalX << " , " << finalY << endl;

    //Iteramos a traves de la matriz para poner los valores
    Matrix maze(rows, cols);
    for(int i = 0; i < maze.rows; i++) {
        for(int j = 0; j < maze.cols; j++) {
            fscanf(file_ptr, "%hu", &maze(i, j));
        }
    }

    //Debug print
    for(int i = 0; i < maze.rows; i++) {
        for(int j = 0; j < maze.cols; j++) {
            cout << maze(i, j) << " ";
        }
        cout << endl;
    }

    aStarSearch(maze, initialX, initialY, finalX, finalY);
    return 0;
}