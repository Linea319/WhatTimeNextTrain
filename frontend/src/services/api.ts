/**
 * API サービス
 * 
 * バックエンドAPIとの通信を行うサービスクラス
 */

import axios, { AxiosInstance } from 'axios';
import type { 
  NextTrainResponse, 
  AllTrainsResponse, 
  HealthResponse,
  ProfilesResponse,
} from '../types/api';

class ApiService {
  private api: AxiosInstance;

  constructor() {
    // APIベースURLの設定
    const baseURL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5000/api';
    
    this.api = axios.create({
      baseURL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // レスポンスインターセプターでエラーハンドリング
    this.api.interceptors.response.use(
      (response) => response,
      (error) => {
        console.error('API Error:', error);
        return Promise.reject(error);
      }
    );
  }

  /**
   * ヘルスチェック
   * サーバーの状態を確認します
   */
  async healthCheck(): Promise<HealthResponse> {
    const response = await this.api.get<HealthResponse>('/health');
    return response.data;
  }

  /**
   * プロファイル一覧を取得
   * 利用可能なプロファイル一覧を取得します
   */
  async getProfiles(): Promise<ProfilesResponse> {
    const response = await this.api.get<ProfilesResponse>('/profiles');
    return response.data;
  }

  /**
   * プロファイル指定で次の列車情報を取得
   * 指定されたプロファイルから次に乗車できる列車の情報を取得します
   */
  async getNextTrainByProfile(profileName: string): Promise<NextTrainResponse> {
    const response = await this.api.get<NextTrainResponse>(`/profile/${profileName}/next-train`);
    return response.data;
  }

  /**
   * プロファイル指定で全列車情報を取得
   * 指定されたプロファイルの時刻表全列車情報を取得します
   */
  async getTrainsByProfile(profileName: string): Promise<AllTrainsResponse> {
    const response = await this.api.get<AllTrainsResponse>(`/profile/${profileName}/trains`);
    return response.data;
  }
}

// シングルトンインスタンスを作成
export const apiService = new ApiService();
export default apiService;
