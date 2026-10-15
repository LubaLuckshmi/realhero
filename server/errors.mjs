export class PublicError extends Error {
  constructor(status, code, message) {
    super(message); this.status = status; this.code = code;
  }
}

export function publicError(error) {
  return error instanceof PublicError ? error
    : new PublicError(500, 'internal_error', 'Лея сейчас недоступна. Данные сохранены; попробуйте ещё раз.');
}
