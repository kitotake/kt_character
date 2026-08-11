// src/utils/misc.ts

export const isEnvBrowser = (): boolean => {
  return typeof (window as any).invokeNative === "undefined";
};

export const noop = () => {};

export const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));