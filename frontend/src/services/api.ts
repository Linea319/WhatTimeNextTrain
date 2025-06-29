/**
 * API サービス
 * 
 * バックエンドAPIとの通信を行うサービスクラス
 */

import axios, { AxiosInstance } from 'axios';
import type { 
  NextTrainResponse, 
  AllTrainsResponse, 
  ConfigResponse, 
  HealthResponse 
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
   * 次の列車情報を取得
   * 現在時刻から次に乗車できる列車の情報を取得します
   */
  async getNextTrain(): Promise<NextTrainResponse> {
    const response = await this.api.get<NextTrainResponse>('/next-train');
    return response.data;
  }

  /**
   * 全ての列車情報を取得
   * 時刻表の全列車情報を取得します
   */
  async getAllTrains(): Promise<AllTrainsResponse> {
    const response = await this.api.get<AllTrainsResponse>('/trains');
    return response.data;
  }

  /**
   * アプリケーション設定を取得
   * 移動時間などの設定情報を取得します
   */
  async getConfig(): Promise<ConfigResponse> {
    const response = await this.api.get<ConfigResponse>('/config');
    return response.data;
  }
}

// シングルトンインスタンスを作成
export const apiService = new ApiService();
export default apiService;
