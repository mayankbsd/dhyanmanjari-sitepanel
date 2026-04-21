class ApiConstants {


  //static  String baseUrl = 'https://iariya.com/api/';
  //static  String baseUrl = 'http://192.168.1.6:5000/api';
  static  String baseUrl = 'https://dhayanmanjari.vercel.app/api';
  //static  String baseUrl = 'http://localhost:5000/api';
  static  String token ="Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImRlZmF1bHRfYXBwIiwiaWF0IjoxNzcyOTUxMzM5LCJleHAiOjE4NTkyNjQ5Mzl9.ayv3UPbmynwC2Ij8K83hrU-OvCxFXSPxBmD5XOSJQwA";


  // Auth endpoints
  static final String getAarties = '$baseUrl/aartis';
  static final String getMatra = '$baseUrl/mantras';
  static final String getChalisa = '$baseUrl/chalisha';
  static final String getCategories = '$baseUrl/categories';
  static final String getGranth = '$baseUrl/granths';
  static final String checkUsername = '$baseUrl/check-username';
  static final String register = '$baseUrl/register';
  static final String login = '$baseUrl/login';
  static final String incrementCount = '$baseUrl/mantra/increment';
  static final String todayMantra = '$baseUrl/mantra/today';
  static final String weekGraph = '$baseUrl/mantra/weekly';
  static final String activeMantra = '$baseUrl/mantra/active-list';
  static final String leaderboard = '$baseUrl/mantra/leaderboard';
  static final String notification = '$baseUrl/notifications/my';
  static final String todayTopMantra = '$baseUrl/mantra/today-top';
  static final String deleteAccount = '$baseUrl/auth/delete-account';
  static final String feedback = '$baseUrl/feedback';
  static final String suggesstion = '$baseUrl/add-suggestion';
  static final String review = '$baseUrl/add-review';
  static final String choghadiya = '$baseUrl/choghadiya/today';
  static final String panchang = '$baseUrl/panchang/today';



  static final String dashStats = '$baseUrl/dashboard/stats';
  static final String aarti = '$baseUrl/aartis';
  static final String chalisha = '$baseUrl/chalisha';
  static final String mantra = '$baseUrl/mantras';




}
