import 'package:dio/dio.dart';import '../config/app_config.dart';
class ApiClient{ApiClient():dio=Dio(BaseOptions(baseUrl:AppConfig.apiBaseUrl,connectTimeout:const Duration(seconds:20),receiveTimeout:const Duration(seconds:30)));final Dio dio;void setToken(String token)=>dio.options.headers['Authorization']='Bearer $token';}
