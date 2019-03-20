# Parallel-Brute-Force-Algorithm (GPGPU using CUDA)

## Overview
This program find password using GPU power not CPU intensive.

## How to run
<ul>
  <li> Visual Studio 2015 or Visual Studio 2017 설치 </li>
  <li> Cuda 9.0 설치 </li>
  <li> NVIDIA 프로젝트 생성 후 소스파일 생성 </li>
  <li> CUDA 프로그램은 1~2초 안에 프로그램이 정상종료되지않을 경우 프로그램이 강제 . 따라서 연산이 오래걸리는 프로그램을 실행시키기 위해서는 반드시 Nsight monitor 프로그램에서 window tdr을 disable로 설정해야한다. </li>
</ul>


## Environtment
<p>Platform : Window 10</p>
<p>Compiler : NVCC + MSVC</p>
<p>CPU : intel i7</p>
<p>GPU : GTX1050</p>




## Result

### CPU
<img width="1018" alt="2019-03-01 1 19 06" src="https://user-images.githubusercontent.com/12508269/53580969-0da22300-3bc0-11e9-99a0-a6f5918ff887.png">

### GPU
![gpu_ver1](https://user-images.githubusercontent.com/12508269/53581099-4cd07400-3bc0-11e9-8e4f-e0b6ae2d70d4.PNG)


### Comparison
<p> CPU: 45 min </p>
<p> GPU: 1287.08 ms </p>
