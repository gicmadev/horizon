const log = (level, ...args) => {
  window.uploader_log = window.uploader_log || [];
  const formatted_log = [
    document.location.href,
    new Date(),
    `${level}`.toUpperCase(),
    ...args
  ];
  window.uploader_log.push(formatted_log);
  (typeof console[level] === "function" ? console[level] : console.log)(
    formatted_log
  );
};

export default {
  log: log.bind(null, "log"),
  debug: log.bind(null, "debug"),
  error: log.bind(null, "error"),
  getLogs: () => window.uploader_log
};
