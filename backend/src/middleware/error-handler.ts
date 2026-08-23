import { Request, Response, NextFunction } from 'express';
import { logger } from '../utils/logger';

interface AppError extends Error {
  status?: number;
  code?: string;
}

export const errorHandler = (
  error: AppError,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  const status = error.status || 500;
  const message = error.message || 'Internal Server Error';

  logger.error(`Error: ${message}`, {
    status,
    path: req.path,
    method: req.method,
    stack: error.stack,
  });

  res.status(status).json({
    success: false,
    error: {
      message,
      code: error.code || 'INTERNAL_ERROR',
      status,
    },
  });
};
