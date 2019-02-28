#include <iostream>
#include <fstream>
#include <string>
#include <cstdio>
#include <stdlib.h>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

using namespace std;

#if defined(NDEBUG)
#define CUDA_CHECK(x)	(x)
#else
#define CUDA_CHECK(x)	do {\
		(x); \
		cudaError_t e = cudaGetLastError(); \
		if (cudaSuccess != e) { \
			printf("cuda failure \"%s\" at %s:%d\n", \
			       cudaGetErrorString(e), \
			       __FILE__, __LINE__); \
			exit(1); \
		} \
	} while (0)
#endif


__device__ void my_strcpy(char *dest, const char *src) {
	int i = 0;
	do {
		dest[i] = src[i];
	} while (src[++i] != '\0');
}
__device__ int my_strlen(char *string) {
	int cnt = 0;
	while (string[cnt] != '\0') {
		++cnt;
	}
	return cnt;
}

__device__ int my_comp(char* str1, char* str2, int N) {
	int flag = 0;

	for (int i = 0; i<N; i++) {
		if (str1[i] != str2[i]) {
			flag = 1;
			break;
		}
	}

	return flag;
}

__global__ void bruteforce(char* pass, char* alphabet, char* dest, int N, long long int next) { // N = alphabet length 
	extern __shared__ char s_alphabet[];

	char test[100]; // char test = (char*)malloc(sizeof(char)*N);
	int digit[7] = { 0, };
	int passLen = my_strlen(pass);

	for (int i = 0; i<N; i++)
		s_alphabet[i] = alphabet[i];

	digit[6] = blockIdx.x >= N*N*N ? (int)((blockIdx.x / (N*N*N)) % N) : 0;
	digit[5] = blockIdx.x >= N*N ? (int)((blockIdx.x / (N*N)) % N) : 0;
	digit[4] = blockIdx.x >= N ? (int)((blockIdx.x / N) % N) : 0;
	digit[3] = (int)(blockIdx.x % N);
	digit[2] = threadIdx.x;
	digit[1] = 0;
	digit[0] = 0;

	while (digit[1] < N) {
		for (int i = 0; digit[0] < N; digit[0]++, ++i) {
			test[0] = s_alphabet[digit[0]];

			for (int j = 1; j < passLen; j++) {
				test[j] = s_alphabet[digit[j]];
			}
			test[passLen] = '\0';

			if (!my_comp(pass, test, passLen)) {
				my_strcpy(dest, test);
				dest[passLen] = '\0';
				return;
			}
		}
		++digit[1];
		digit[0] = 0;
	}
}

__global__ void bruteforce_write(char* pass, char* alphabet, char* dest, int N, long long unsigned int ExecutionPerThread, long long unsigned total_len) { // N = alphabet length 
	// we don't use shared memory in this function.

	char test[100]; // char test = (char*)malloc(sizeof(char)*N);
	int digit[7] = { 0, };
	int passLen = my_strlen(pass);
	long long unsigned int idx = 0;
	long long unsigned int dummy = 0;

	digit[6] = blockIdx.x >= N*N*N ? (int)((blockIdx.x / (N*N*N)) % N) : 0;
	digit[5] = blockIdx.x >= N*N ? (int)((blockIdx.x / (N*N)) % N) : 0;
	digit[4] = blockIdx.x >= N ? (int)((blockIdx.x / N) % N) : 0;
	digit[3] = (int)(blockIdx.x % N);
	digit[2] = threadIdx.x;
	digit[1] = 0;
	digit[0] = 0;
	
	// ExecutionPerThread = alphabetLen * alphabeltLen * passLen
	while (digit[1] < N) {
		for (int i = 0; digit[0] < N; digit[0]++, ++i) {
			if (blockIdx.x)
				idx = (threadIdx.x * ExecutionPerThread + (i + dummy) * passLen) * blockDim.x * blockIdx.x;
			else
				idx = threadIdx.x * ExecutionPerThread + (i + dummy) * passLen;

			if (idx > total_len) return;

			dest[idx++] = alphabet[digit[0]];

			for (int j = 1; j < passLen; j++) {
				dest[idx++] = alphabet[digit[j]];
			}
		}
		dummy += N ;
		++digit[1];
		digit[0] = 0;
	}
}

void crackPassword(string, int, int);

int main() {
	system("mode con cols=200 lines=250");

	string password;
	string cracked;
	int operation = 0;
	int numOfChars = -1;

	while (operation != 1 && operation != 2) {
		cout << "******* BRUTE FORCE PROGRAM *******" << endl;
		cout << "******* [1]. JUST FIND " << endl;
		cout << "******* [2]. WRITE " << endl;
		cout << "INPUT NUMBER HERE : ";
		cin >> operation;
	}

	if (operation == 2) {
		while (numOfChars <= 0) {
			cout << "INPUT NUMBER OF CHARACTERS(FROM 1 TO 7) : ";
			cin >> numOfChars;
			for (int i = 0; i < numOfChars; i++)
				password += 'a';
		}
	}
	else {
		cout << "Enter the password to crack : ";
		cin >> password;
	}

	crackPassword(password, operation, numOfChars);

	cout << endl;

	return 0;
}

void crackPassword(string pass, int operation, int numOfChars) {
	cudaEvent_t start, stop;
	string alphabet;
	string str("");
	char* result;
	char* d_pass;
	char* d_alphabet;
	char* d_dest;
	int alphabetSet = 1;
	int len;
	int cnt = 0;
	int new_cnt = 0;
	int passLen = pass.length();
	float ms = 0;
	char* temp = (char*)malloc(sizeof(char)*pass.length() + 1);
	ofstream ofs("password.txt");
	long long unsigned int total_len;
	bool isFind = false;
	string line("");

	memset(temp, 0, sizeof(char)*pass.length() + 1);
	result = (char*)malloc(sizeof(char)*pass.length() + 1);
	CUDA_CHECK(cudaEventCreate(&start));
	CUDA_CHECK(cudaEventCreate(&stop));
	CUDA_CHECK(cudaMalloc((void**)&d_pass, sizeof(char)*pass.length() + 1));
	CUDA_CHECK(cudaMalloc((void**)&d_dest, sizeof(char)*pass.length() + 1));
	CUDA_CHECK(cudaMemcpy(d_pass, pass.c_str(), sizeof(char)*pass.length() + 1, cudaMemcpyHostToDevice));
	CUDA_CHECK(cudaMemcpy(d_dest, temp, sizeof(char)*pass.length() + 1, cudaMemcpyHostToDevice));

	CUDA_CHECK(cudaEventRecord(start)); // start gpu computing with cuda
	while (1) {
		memset(result, 0, pass.length() + 1);
		switch (alphabetSet) {
		case 1: alphabet = "0123456789";
			if (operation == 1)
				cout << endl << endl << "Testing only digits(0123456789) - 10 Characters, please wait";
			else
				cout << endl << endl << "...writing";
			break;
		case 2: alphabet = "abcdefghijklmnopqrstuvwxyz";
			if (operation == 1)
				cout << endl << endl << "Couldn't find the password, increasing the searching level." << endl << endl << "Testing only lowercase characters(abcdefghijklmnopqrstuvwxyz) - 26 Characters, please wait";
			else
				cout << endl << endl << "...writing";
			break;
		case 3: alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
			if (operation == 1)
				cout << endl << endl << "Couldn't find the password, increasing the searching level." << endl << endl << "Testing only uppercase characters(ABCDEFGHIJKLMNOPQRSTUVWXYZ) - 26 Characters, please wait";
			else
				cout << endl << endl << "...writing";
			break;
		case 4: alphabet = "0123456789abcdefghijklmnopqrstuvwxyz";
			if (operation == 1)
				cout << endl << endl << "Couldn't find the password, increasing the searching level." << endl << endl << "Testing lowercase characters and numbers(0123456789abcdefghijklmnopqrstuvwxyz) - 36 Characters, please wait";
			else
				cout << endl << endl << "...writing";
			break;
		case 5: alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
			if (operation == 1)
				cout << endl << endl << "Couldn't find the password, increasing the searching level." << endl << endl << "Testing uppercase characters and numbers(0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ) - 36 Characters, please wait";
			else
				cout << endl << endl << "...writing";
			break;
		case 6: alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
			if (operation == 1)
				cout << endl << endl << "Couldn't find the password, increasing the searching level." << endl << endl << "Testing lowercase, uppercase characters(abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ) - 52 Characters, please wait";
			else
				cout << endl << endl << "...writing";
			break;
		case 7: alphabet = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
			if (operation == 1)
				cout << endl << endl << "Couldn't find the password, increasing the searching level." << endl << endl << "Testing lowercase, uppercase characters and numbers(0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ) - 62 Characters, please wait";
			else
				cout << endl << endl << "...writing";
			break;
		}
		len = alphabet.length();
		CUDA_CHECK(cudaMalloc((void**)&d_alphabet, sizeof(char)*len + 1));
		CUDA_CHECK(cudaMemcpy(d_alphabet, alphabet.c_str(), sizeof(char)*len + 1, cudaMemcpyHostToDevice));

		dim3 threadsPerBlock(len, 1);
		dim3 blocksPerGrid((int)std::pow((float)len, pass.length() < 3 ? 1 : (float)(pass.length() - 3)), 1);
		
		switch (operation) {
			case 1: // JUST FIND
				bruteforce<<<blocksPerGrid, threadsPerBlock, sizeof(char) * len >>>(d_pass, d_alphabet, d_dest, len, 0);
				
				CUDA_CHECK(cudaMemcpy(result, d_dest, sizeof(char)*pass.length() + 1, cudaMemcpyDeviceToHost));

				str = result;
				if (str.compare(pass) == 0) {
					CUDA_CHECK(cudaEventRecord(stop));
					cudaEventSynchronize(stop);
					cout << endl << "the password : " << result << endl;
					CUDA_CHECK(cudaEventElapsedTime(&ms, start, stop));
					cout << "The time duration  passed : " << ms << "ms" << endl << endl;
					isFind = true;
					free(result);
				}			
				
				break;
			case 2: // WRITE
				total_len = (long long unsigned int)(sizeof(char) *  len*len*pass.length() * threadsPerBlock.x * blocksPerGrid.x);
				CUDA_CHECK( cudaMalloc((void**)&d_dest, total_len) );
				bruteforce_write<<<blocksPerGrid, threadsPerBlock>>>(d_pass, d_alphabet, d_dest, len, (long long unsigned int)len*len*pass.length(), total_len );
				result = (char*)malloc(total_len);
				CUDA_CHECK(cudaMemcpy(result, d_dest, total_len , cudaMemcpyDeviceToHost));
				
				// file write
				while(cnt <= total_len) {
					line = "";
					new_cnt = 0;
					while (new_cnt < passLen) {
						if ( (strchr(alphabet.c_str(), result[cnt]) != NULL) && result[cnt] != '\0' ) {
							line += result[cnt];
							new_cnt++;
						}
						cnt++;
						if (cnt >= total_len)
							break;
					}
					ofs << line << endl;
				}	
				cnt = 0;
				new_cnt = 0;
				CUDA_CHECK(cudaFree(d_dest));
				free(result);
				break;
		}

		alphabetSet++;
		CUDA_CHECK(cudaFree(d_alphabet));

		if (alphabetSet > 7) 
			break;
		if (isFind == true)
			break;
	}

	CUDA_CHECK(cudaFree(d_pass));
	if(operation == 1)
		CUDA_CHECK(cudaFree(d_dest));
}
