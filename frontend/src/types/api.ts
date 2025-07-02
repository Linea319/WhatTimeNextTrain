/**
 * API レスポンスの型定義
 * 
 * バックエンドAPIのレスポンス構造に対応する型を定義します
 */

// 列車情報の型
export interface Train {
  line: string;
  destination: string;
  departure_time: string;
  arrival_time: string;
}

// 次の列車情報APIレスポンスの型
export interface NextTrainResponse {
  current_time: string;
  departure_time: string;
  departure_station: string;
  arrival_time: string;
  time_until_departure: number;
  station_name: string;
  train: Train | null;
  error?: string;
}

// 全列車情報APIレスポンスの型
export interface AllTrainsResponse {
  station_name: string;
  trains: Train[];
  error?: string;
}

// アプリケーション設定APIレスポンスの型
export interface ConfigResponse {
  station_name: string;
  home_to_station_minutes: number;
  preparation_minutes: number;
  update_interval_seconds: number;
}

// ヘルスチェックAPIレスポンスの型
export interface HealthResponse {
  status: string;
  timestamp: string;
}

// プロファイル情報の型
export interface Profile {
  name: string;
  departure: string;
  destinations: Array<{ station: string; duration_minutes?: string }>;
}

// プロファイル一覧APIレスポンスの型
export interface ProfilesResponse {
  profiles: Profile[];
  error?: string;
}
