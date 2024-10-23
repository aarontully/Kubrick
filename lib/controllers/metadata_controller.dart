import 'package:get/get.dart';
import 'package:kubrick/models/metadata_class.dart';

class MetadataController extends GetxController {
  final shootday = ''.obs;
  final interviewDay = ''.obs;
  final contestant = ''.obs;
  final camera = ''.obs;
  final audio = ''.obs;
  final producer = ''.obs;

  final List<String> contestants = [
    '',
    'DAVID',
    'LUKE',
    'GEORGE',
    'SHONEE',
    'SARAH',
    'KIRBY',
    'TONY',
    'ROB',
    'TOMMI',
    'PARVATI',
    'CIRIE',
    'LISA',
    'KASS',
  ];
  final List<String> producers = [
    '',
    'BEN HEWETT',
    'MARIA HANDAS',
    'EMMA VICKERY',
    'MOUNYA WISE',
    'DANE MOLTZEN',
    'ANDREA REHRIG',
    'JASMINE VANDENBERG',
    'ALEX GILLESPIE',
    'SCOTT HERRMAN',
    'ALEISHA MCCORMACK',
    'CHARLOTTE FREEMAN HALL',
    'JACOB REID',
    'DOMINIC OBRIEN',
    'ALEXANDRA CASACLANG',
    'HAYDEN WHEELER',
    'JACOB LUNNEY',
    'BEAUMONT CHIVERS',
    'TOM BACKWELL',
    'LAUREN ANDERSON'
  ];

  void setMetadata(Metadata metadata) {
    shootday.value = metadata.shoot_day;
    interviewDay.value = metadata.interview_day;
    contestant.value = metadata.contestant;
    camera.value = metadata.camera;
    audio.value = metadata.audio;
    producer.value = metadata.producer;
  }
}
