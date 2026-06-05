import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../models/medicine_model.dart';

class MedicineService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
  ));

  Future<List<MedicineModel>> getAll({String search = ''}) async {
    final res = await _dio.get('/medicines', queryParameters: {'search': search});
    final list = res.data['data'] as List;
    return list.map((e) => MedicineModel.fromJson(e)).toList();
  }

  Future<MedicineModel> getById(int id) async {
    final res = await _dio.get('/medicines/$id');
    return MedicineModel.fromJson(res.data['data']);
  }

  Future<MedicineModel> create(Map<String, dynamic> data) async {
    final res = await _dio.post('/medicines', data: data);
    return MedicineModel.fromJson(res.data['data']);
  }

  Future<MedicineModel> update(int id, Map<String, dynamic> data) async {
    final res = await _dio.put('/medicines/$id', data: data);
    return MedicineModel.fromJson(res.data['data']);
  }

  Future<void> delete(int id) async {
    await _dio.delete('/medicines/$id');
  }
}
