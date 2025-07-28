import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/member.dart';
import '../core/api_config.dart';

class MemberService {

  // Buscar todos os membros
  static Future<List<Member>> getAllMembers() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.membersUrl));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Member.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao carregar membros: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Buscar membro por ID
  static Future<Member> getMemberById(int id) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.membersUrl}/$id'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Member.fromJson(data);
      } else {
        throw Exception('Falha ao carregar membro: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Criar novo membro
  static Future<Member> createMember(Member member) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.membersUrl),
        headers: ApiConfig.defaultHeaders,
        body: json.encode(member.toJson()),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Member.fromJson(data);
      } else {
        throw Exception('Falha ao criar membro: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Atualizar membro
  static Future<Member> updateMember(Member member) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.membersUrl}/${member.id}'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode(member.toJson()),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Member.fromJson(data);
      } else {
        throw Exception('Falha ao atualizar membro: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Deletar membro
  static Future<void> deleteMember(int id) async {
    try {
      final response = await http.delete(Uri.parse('${ApiConfig.membersUrl}/$id'));
      
      if (response.statusCode != 200) {
        throw Exception('Falha ao deletar membro: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Buscar membros com pagamento em atraso
  static Future<List<Member>> getOverdueMembers() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.membersUrl}/overdue'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Member.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao carregar membros em atraso: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Verificar se a exclusão de um membro foi completa
  static Future<Map<String, dynamic>> verifyDeletion(int memberId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.membersUrl}/verify-deletion/$memberId'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception('Falha ao verificar exclusão: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Buscar membros por status de pagamento
  static Future<List<Member>> getMembersByPaymentStatus(String status) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.membersUrl}/payment-status/$status'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Member.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao carregar membros: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
} 