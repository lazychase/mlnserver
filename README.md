# mlnserver
C++ ���� �����ӿ�ũ [mlnsdk](https://github.com/lazychase/mlnsdk) �� ���� ���� ���� ������Ʈ �Դϴ�.

# ����
## on Windows
visual studio ���� CMakeLists.txt �� �����ϼ���.
![run on vs](https://user-images.githubusercontent.com/97491125/148936553-c7738242-a97e-472b-9d8f-f04efcad6905.jpg)
## on Linux
������ ��Ÿ��ȯ�� ��Ŀ�̹����� mlnserver ��Ŀ������ �غ��Ͽ����ϴ�. docker/Dockerfile �� ����Ͽ� ������ �� �ֽ��ϴ�.
```
docker build --no-cache -t chase81/mlnserver .
docker run --name mlnserver chase81/mlnserver
```
