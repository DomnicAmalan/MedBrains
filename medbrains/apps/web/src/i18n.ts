import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import HttpBackend from "i18next-http-backend";

const NS = [
  "common",
  "nav",
  "clinical",
  "dashboard",
  "patients",
  "opd",
  "lab",
  "pharmacy",
  "billing",
  "ipd",
  "admin",
] as const;

i18n
  .use(HttpBackend)
  .use(initReactI18next)
  .init({
    lng: "en",
    fallbackLng: "en",
    ns: [...NS],
    defaultNS: "common",
    backend: {
      loadPath: "/locales/{{lng}}/{{ns}}.json",
    },
    interpolation: {
      escapeValue: false,
    },
    react: {
      useSuspense: false,
    },
  });

export default i18n;
