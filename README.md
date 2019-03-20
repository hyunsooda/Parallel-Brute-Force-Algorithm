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
![cpu5글자대소문자숫자](https://user-images.githubusercontent.com/12508269/54700769-fe871300-4b76-11e9-87b6-7a3ed7159c1f.PNG)
![cpu5글자대소문자숫자-1](https://user-images.githubusercontent.com/12508269/54700772-ffb84000-4b76-11e9-8f7f-907bfd03d8ad.PNG)

### GPU
![5글자-gpu](https://user-images.githubusercontent.com/12508269/54700748-f5964180-4b76-11e9-8ce4-15adcafbfeec.PNG)


