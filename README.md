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

# 실행을 위해 예제에서 준비된 것들
통신을 위해 사용자가 준비해야 하는 것들은 다음과 같습니다.(이하 프로토콜세트)
1. 패킷 구조체 정의
2. 패킷 구조에 의존한 패킷을 송수신하는 방법
3. 각 패킷 및 패킷 처리부

이 프로젝트에서는 기본으로 제공하는 프로토콜세트를 사용하여 서버와 클라이언트를 실행하는 방법을 예시하고 있습니다.

## 서버 준비
### 네트워크 이벤트를 수신할 객체를 생성합니다.
```
class ServiceEventReceiver
	{
	public:
		void onAccept(mln::net::Session::sptr session);
		void onAcceptFailed(mln::net::Session::sptr session);
		void onClose(mln::net::Session::sptr session);
		void onCloseFailed(mln::net::Session::sptr session);
		void onUpdate(uint64_t deltaTimsMs);
		void onExpiredSession(mln::net::Session::sptr session);
		void noHandler(mln::net::Session::sptr session, mln::net::ByteStream& byteStream);
	public:
		void initHandler(mln::net::PacketProcedure* packetProc);
	};
```
위의 예시에 보이는 함수들을 public 인터페이스로 가진 클래스가 필요합니다.
* onAccept, onAcceptFailed : 클라이언트가 접속(접속실패) 시 호출됨
* onClose, onCloseFailed : 클라이언트가 종료(종료실패) 시 호출됨
* onUpdate : deltaTimeMs 마다 호출됨. 호출 주기는 0 이외의 값으로 제공 시 동작합니다.
* onExpiredSession : 만료시간을 지정할 경우, 지정된 시간동안 통신이 없는 세션이 통지됨
* noHandler : 등록되지 않은 패킷 요청을 수신하였을때 호출됨
* initHandler : 이 부분에 사용자 패킷 및 핸들러를 등록합니다.

### 패킷 및 핸들러 등록
initHandler 함수는 서비스가 초기화될때 호출이 됩니다. 이곳에서 수신할 패킷의 식별자와 핸들러를 등록합니다. 미리 정의해둔 json packet 프로토콜은 문자열을 기반으로 하고 있습니다.

```
void ServiceEventReceiver::initHandler(PacketProcedure* packetProcedure)
{
	using namespace mln::net;

	// packetJson::PT_JSON 패킷을 등록.
	auto static handler = PacketJsonHandler<web::json::value>();
	handler.init(packetProcedure);
	handler.setJsonBodyParser(mln::net::cpprest::parse);

	// 서브패킷들(json packets)을 등록
	handler.registJsonPacketHandler("/lobby/login", [](
		UserBase::sptr userBase
		, const std::string& url
		, auto & jv
		) {

		assert(url == "/lobby/login");

		LOGD("received packet from client. (C->S) url:{}", url);
		auto receivedJsonString = jv.serialize();
		std::cout << CONV_UTF8(receivedJsonString) << std::endl;


		auto user = std::static_pointer_cast<User>(userBase);
		std::string replyString(receivedJsonString.begin(), receivedJsonString.end());
		user->sendJsonPacket(url, replyString);
	});

}
```
패킷 식별자가 '/lobby/login' 이고, 동작은 수신한 json 문자열을 출력 후 다시 돌려주는 기능입니다.

### 서버 서비스 실행
준비한 이벤트 수신 클래스로 서비스를 등록합니다.
```
using namespace mlnserver;
	using namespace mln::net;

	ServiceEventReceiver eventReceiver;

	auto acceptor = NetService::accept(
		eventReceiver
		, *g_ioc.get()
		, 9090
	);
```
9090 포트로 서비스를 시작하였습니다. g_ioc 는 boost::asio::io_context 객체입니다.  
이렇게 하면 서버사이드는 준비가 끝났습니다.

## 클라이언트 준비
클라이언트도 서버를 준비할때와 마찬가지로 네트워크 이벤트를 수신할 클래스를 준비하고 패킷 및 핸들러를 등록합니다.
```
class SampleConnector
	{
	public:
		void onConnect(mln::net::Session::sptr session) {
			LOGD("onConnect - {}/{}"
				, session->socket().remote_endpoint().address().to_string()
				, session->socket().remote_endpoint().port());

			// create user.
			auto user = std::make_shared<User>(session);
			session->setUser(user);

			std::istringstream json_data(R"json(
  {
    "how": "are",
    "you": "Im",
    "fine": "thx",
    "andu": "hello everyone"
}
 )json");
			auto ss = json_data.str();

			user->sendJsonPacket("/lobby/login", ss);
		}

		void onConnectFailed(mln::net::Session::sptr session) {
			LOGE("onConnectFailed");
		}

		void onClose(mln::net::Session::sptr session) {
			LOGD("onClose - {}/{}"
				, session->socket().remote_endpoint().address().to_string()
				, session->socket().remote_endpoint().port());
		}
		void onCloseFailed(mln::net::Session::sptr session) {}

		void onUpdate(uint64_t elapse) {}
		void onExpiredSession(mln::net::Session::sptr session) {}
		void noHandler(mln::net::Session::sptr session, mln::net::ByteStream& packet) {}

	public:
		void initHandler(mln::net::PacketProcedure* packetProcedure) {
			using namespace mln::net;

			auto static handler = PacketJsonHandler<web::json::value>();

			handler.init(packetProcedure);
			handler.setJsonBodyParser(mln::net::cpprest::parse);
			handler.registJsonPacketHandler("/lobby/login", [](
				UserBase::sptr user
				, const std::string& url
				, auto& jv
				) {
				assert(url == "/lobby/login");

				LOGD("received packet from server. (S->C) url:{}", url);
				std::cout << CONV_UTF8(jv.serialize()) << std::endl;
			});
		}
```
네트워크 이벤트는 서버와 유사합니다. 서버에서는 accept 이벤트를, 클라이언트에서는 connect 이벤트를 수신하는 차이가 있습니다.  
위의 코드에서는 '/lobby/login' 패킷을 수신하면 화면에 출력하는 핸들러를 등록합니다.

그리고 아래와 같이 서버로 접속하는 클라이언트 서비스를 실행합니다
```
SampleConnector connectorInstance;

mln::net::NetService::connect(
	connectorInstance
	, ioc
	, "127.0.0.1"
	, 9090
);
```

그리고 프로젝트를 실행하면 서버와 클라이언트가 패킷을 주고받아 출력하는 결과를 확인할 수 있습니다.
![run on vs](https://user-images.githubusercontent.com/97491125/149047325-f5e41979-c76d-4139-ae88-a9a0a592d659.jpg)


# 빠르게 사용하기
샘플 프로젝트를 그대로 사용하면서 패킷 핸들러를 등록하는 코드( handler.registJsonPacketHandler ) 에 원하는 패킷을 추가해서 사용 가능합니다.

# 패킷 프로토콜 커스텀
자신만의 패킷 구조와 다루는 방법을 정의하여 서비스 파라미터로 제공하여 사용가능합니다. 편의함수에서는  PacketJsonParser를 사용하고 있습니다.  
### 서비스 파라미터에 커스텀 프로토콜 정보 지정
```
mln::net::ServiceParams serviceInitParams{
	ioc
	, userHandler                           // -> 네트워크 이벤트 수신 객체
	, mln::net::PacketJsonParser::parse     // -> 패킷 파서
	, mln::net::PacketJsonParser::get()     // -> 패킷 헤더 조작함수
	, 1000                                  // -> onUpdate 함수가 호출되는 주기(ms)
	, 0                                     // -> 만료시간( 세션을 사용하지 않을 때 onExpiredSession 함수가 호출되는 시간)
};
```
### Json 라이브러리 지정
기본 구현으로 microsoft의 cpprestsdk 의 json 구조체를 제공하고 있습니다. 지정 코드는 이것이고,
```
handler.setJsonBodyParser(mln::net::cpprest::parse);
```
지정한 함수는 바이너리 스트림을 입력받아 해당 라이브러리의 json value 객체를 반환하는 인터페이스를 가져야 합니다. 아래는 cpprest 의 json value 를 반환하는 함수입니다.
```
namespace mln::net::cpprest {
	static std::tuple<bool, web::json::value> parse(unsigned char* body, uint32_t bodySize) {

		try {
			std::string myJsonString((char*)body, bodySize);
			return { true, web::json::value::parse(myJsonString) };
		}
		catch (std::exception e) {
			return { false, web::json::value::null() };
		}
	}
}//namespace mln::net::mlncpprest {
```