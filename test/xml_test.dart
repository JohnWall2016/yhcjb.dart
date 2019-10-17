import 'package:xml/xml.dart';
import 'package:yhcjb/src/xml/xml.dart';
import 'package:yhcjb/yhqb.dart';

main() {
  var en = RequestEnvelop(SncbrycxRequest('430302195806251012'));
  print(en.toXmlString());

  var xml = parse(test);
  var env = findChild(xml, 'Envelope');
  if (env != null) {
    var header = findChild(env, 'Header');
    print(Resultable.convert(header));
    var body = findChild(env, 'Body');
    var business = findChild(body, 'business');
    print(Resultable.convert(business));
  }

  var res = ResponseEnvelop.fromXmlString<SncbrycxResponse>(test);
  print('${res.header.sessionID}|${res.header.message}');
  print('${res.body.result}|${res.body.row_count}');
  for (var item in res.body.querylist) {
    print('${item.name}|${item.idcard}|${item.sbjg}');
  }
}

var test = '''
<?xml version="1.0" encoding="GBK"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <soap:Header>
    <result sessionID="DpPZb8mZ0qgv08kN26LyKmm1yDz4nn7QvXxh2VD32vDvgvQ2zw14!-23337339!1530701497001"/>
    <result message=""/>
  </soap:Header>
  <soap:Body>
    <out:business xmlns:out="http://www.molss.gov.cn/">
      <result result="" />
      <resultset name="querylist">
        <row aac003="徐X" rown="1" aac008="2" aab300="XXXXXXX服务局" sac007="101" aac031="3" aac002="43030219XXXXXXXXXX" />
      </resultset>
      <result row_count="1" />
      <result querysql="select * from 
  from ac01_css a, ac02_css b
 where a.aac001 = b.aac001) where ( aac002 = &apos;43030219XXXXXXXX&apos;) and 1=1) row_ where rownum &lt;(501)) where rown &gt;=(1) " />
    </out:business>
  </soap:Body>
</soap:Envelope>
''';