/// <reference types="vite/client" />

declare module '*.vue' {
  import type { DefineComponent } from 'vue'
  const component: DefineComponent<{}, {}, any>
  export default component
}

interface ImportMetaEnv {
  readonly VITE_API_BASE_URL: string; // APIのベースURL TODO: 実際のAPIエンドポイントに置き換える
  // 他の環境変数がある場合はここに追加
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
