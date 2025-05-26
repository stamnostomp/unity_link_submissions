export function isValidNameFormat(name) {
  const parts = name.split('.');
  return parts.length === 2 && parts.every(part => part.length > 0);
}
