# mlnserver
C++ 서버 프레임워크 [mlnsdk](https://github.com/lazychase/mlnsdk) 로 만든 예제 서버 프로젝트 입니다.

# 실행
## on Windows
visual studio 에서 CMakeLists.txt 를 실행하세요.
![run on vs](https://user-images.githubusercontent.com/97491125/148936553-c7738242-a97e-472b-9d8f-f04efcad6905.jpg)
## on Linux
리눅스 런타임환경 도커이미지와 mlnserver 도커파일을 준비하였습니다. docker/Dockerfile 을 사용하여 실행할 수 있습니다.
```
docker build --no-cache -t chase81/mlnserver .
docker run --name mlnserver chase81/mlnserver
```
