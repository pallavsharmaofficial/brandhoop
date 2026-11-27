export class HttpError extends Error {
  constructor(public statusCode: number, message: string, public code = 'error') {
    super(message);
  }
}
export const badRequest = (m: string) => new HttpError(400, m, 'bad_request');
export const unauthorized = (m = 'Please sign in again') => new HttpError(401, m, 'unauthorized');
export const forbidden = (m = 'You are not allowed to do this') => new HttpError(403, m, 'forbidden');
export const notFound = (m = 'Not found') => new HttpError(404, m, 'not_found');
export const conflict = (m: string) => new HttpError(409, m, 'conflict');
