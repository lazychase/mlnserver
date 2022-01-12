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

# ������ ���� �������� �غ�� �͵�
����� ���� ����ڰ� �غ��ؾ� �ϴ� �͵��� ������ �����ϴ�.(���� �������ݼ�Ʈ)
1. ��Ŷ ����ü ����
2. ��Ŷ ������ ������ ��Ŷ�� �ۼ����ϴ� ���
3. �� ��Ŷ �� ��Ŷ ó����

�� ������Ʈ������ �⺻���� �����ϴ� �������ݼ�Ʈ�� ����Ͽ� ������ Ŭ���̾�Ʈ�� �����ϴ� ����� �����ϰ� �ֽ��ϴ�.

## ���� �غ�
### ��Ʈ��ũ �̺�Ʈ�� ������ ��ü�� �����մϴ�.
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
���� ���ÿ� ���̴� �Լ����� public �������̽��� ���� Ŭ������ �ʿ��մϴ�.
* onAccept, onAcceptFailed : Ŭ���̾�Ʈ�� ����(���ӽ���) �� ȣ���
* onClose, onCloseFailed : Ŭ���̾�Ʈ�� ����(�������) �� ȣ���
* onUpdate : deltaTimeMs ���� ȣ���. ȣ�� �ֱ�� 0 �̿��� ������ ���� �� �����մϴ�.
* onExpiredSession : ����ð��� ������ ���, ������ �ð����� ����� ���� ������ ������
* noHandler : ��ϵ��� ���� ��Ŷ ��û�� �����Ͽ����� ȣ���
* initHandler : �� �κп� ����� ��Ŷ �� �ڵ鷯�� ����մϴ�.

### ��Ŷ �� �ڵ鷯 ���
initHandler �Լ��� ���񽺰� �ʱ�ȭ�ɶ� ȣ���� �˴ϴ�. �̰����� ������ ��Ŷ�� �ĺ��ڿ� �ڵ鷯�� ����մϴ�. �̸� �����ص� json packet ���������� ���ڿ��� ������� �ϰ� �ֽ��ϴ�.

```
void ServiceEventReceiver::initHandler(PacketProcedure* packetProcedure)
{
	using namespace mln::net;

	// packetJson::PT_JSON ��Ŷ�� ���.
	auto static handler = PacketJsonHandler<web::json::value>();
	handler.init(packetProcedure);
	handler.setJsonBodyParser(mln::net::cpprest::parse);

	// ������Ŷ��(json packets)�� ���
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
��Ŷ �ĺ��ڰ� '/lobby/login' �̰�, ������ ������ json ���ڿ��� ��� �� �ٽ� �����ִ� ����Դϴ�.

### ���� ���� ����
�غ��� �̺�Ʈ ���� Ŭ������ ���񽺸� ����մϴ�.
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
9090 ��Ʈ�� ���񽺸� �����Ͽ����ϴ�. g_ioc �� boost::asio::io_context ��ü�Դϴ�.  
�̷��� �ϸ� �������̵�� �غ� �������ϴ�.

## Ŭ���̾�Ʈ �غ�
Ŭ���̾�Ʈ�� ������ �غ��Ҷ��� ���������� ��Ʈ��ũ �̺�Ʈ�� ������ Ŭ������ �غ��ϰ� ��Ŷ �� �ڵ鷯�� ����մϴ�.
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
��Ʈ��ũ �̺�Ʈ�� ������ �����մϴ�. ���������� accept �̺�Ʈ��, Ŭ���̾�Ʈ������ connect �̺�Ʈ�� �����ϴ� ���̰� �ֽ��ϴ�.  
���� �ڵ忡���� '/lobby/login' ��Ŷ�� �����ϸ� ȭ�鿡 ����ϴ� �ڵ鷯�� ����մϴ�.

�׸��� �Ʒ��� ���� ������ �����ϴ� Ŭ���̾�Ʈ ���񽺸� �����մϴ�
```
SampleConnector connectorInstance;

mln::net::NetService::connect(
	connectorInstance
	, ioc
	, "127.0.0.1"
	, 9090
);
```

�׸��� ������Ʈ�� �����ϸ� ������ Ŭ���̾�Ʈ�� ��Ŷ�� �ְ�޾� ����ϴ� ����� Ȯ���� �� �ֽ��ϴ�.
![run on vs](https://user-images.githubusercontent.com/97491125/149047325-f5e41979-c76d-4139-ae88-a9a0a592d659.jpg)


# ������ ����ϱ�
���� ������Ʈ�� �״�� ����ϸ鼭 ��Ŷ �ڵ鷯�� ����ϴ� �ڵ�( handler.registJsonPacketHandler ) �� ���ϴ� ��Ŷ�� �߰��ؼ� ��� �����մϴ�.

# ��Ŷ �������� Ŀ����
�ڽŸ��� ��Ŷ ������ �ٷ�� ����� �����Ͽ� ���� �Ķ���ͷ� �����Ͽ� ��밡���մϴ�. �����Լ�������  PacketJsonParser�� ����ϰ� �ֽ��ϴ�.  
### ���� �Ķ���Ϳ� Ŀ���� �������� ���� ����
```
mln::net::ServiceParams serviceInitParams{
	ioc
	, userHandler                           // -> ��Ʈ��ũ �̺�Ʈ ���� ��ü
	, mln::net::PacketJsonParser::parse     // -> ��Ŷ �ļ�
	, mln::net::PacketJsonParser::get()     // -> ��Ŷ ��� �����Լ�
	, 1000                                  // -> onUpdate �Լ��� ȣ��Ǵ� �ֱ�(ms)
	, 0                                     // -> ����ð�( ������ ������� ���� �� onExpiredSession �Լ��� ȣ��Ǵ� �ð�)
};
```
### Json ���̺귯�� ����
�⺻ �������� microsoft�� cpprestsdk �� json ����ü�� �����ϰ� �ֽ��ϴ�. ���� �ڵ�� �̰��̰�,
```
handler.setJsonBodyParser(mln::net::cpprest::parse);
```
������ �Լ��� ���̳ʸ� ��Ʈ���� �Է¹޾� �ش� ���̺귯���� json value ��ü�� ��ȯ�ϴ� �������̽��� ������ �մϴ�. �Ʒ��� cpprest �� json value �� ��ȯ�ϴ� �Լ��Դϴ�.
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