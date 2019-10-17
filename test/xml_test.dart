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
        <row aac003="徐斌" rown="1" aac008="2" aab300="湖南省社会保险管理服务局" sac007="101" aac031="3" aac002="430302195806251012" />
      </resultset>
      <result row_count="1" />
      <result querysql="select * from (select /*+FIRST_ROWS(500)*/row_.* ,rownum rown  from (select aac002,aac003,aab300,aac031,sac007,aac008 from (select aac002, aac003, aab300, aac031, sac007, aac008, sab100
  from ac01, ab50, ac02
 where ac01.aac001 = ac02.aac001
   and ac01.aab034 = ab50.aab034
   --and ac01.aac002 = &apos;433022197609160913&apos;
union all
select a.aac002,
       a.aac003,
       decode(b.aab324,&apos;430101&apos;,&apos;长沙市&apos;,&apos;430102&apos;,&apos;芙蓉区&apos;,&apos;430103&apos;,&apos;天心区&apos;,&apos;430104&apos;,&apos;岳麓区&apos;,&apos;430105&apos;,&apos;开福区&apos;,&apos;430111&apos;,&apos;雨花区&apos;,&apos;其它&apos;),
       b.aac031,
       decode((select aab019 from ab01_css where aab001 = b.aab001),
              &apos;73&apos;,
              &apos;102&apos;,
              &apos;101&apos;) sac007,
       a.aac008,
       b.aab001
  from ac01_css a, ac02_css b
 where a.aac001 = b.aac001) where ( aac002 = &apos;430302195806251012&apos;) and 1=1) row_ where rownum &lt;(501)) where rown &gt;=(1) " />
    </out:business>
  </soap:Body>
</soap:Envelope>
''';