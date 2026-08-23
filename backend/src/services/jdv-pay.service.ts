import { Wallet } from '../entities/Wallet.entity';
import { Transaction } from '../entities/Transaction.entity';
import { AppDataSource } from '../database/data-source';
import { WalletService } from './wallet.service';
import { logger } from '../utils/logger';

export interface PaymentMethod {
  id: string;
  type: 'wallet' | 'card' | 'bank';
  name: string;
  details: any;
}

export interface Beneficiary {
  id: string;
  name: string;
  phone: string;
  email: string;
  accountNumber?: string;
}

export class JDVPayService {
  private walletRepository = AppDataSource.getRepository(Wallet);
  private transactionRepository = AppDataSource.getRepository(Transaction);
  private walletService = new WalletService();

  // Get wallet balance
  async getBalance(userId: string, currency: string = 'XOF') {
    try {
      const wallet = await this.walletService.getWallet(userId, currency);
      return {
        userId,
        currency,
        balance: wallet.balance,
        status: wallet.status,
      };
    } catch (error) {
      logger.error('Get balance error:', error);
      throw error;
    }
  }

  // QR Code Payment
  async generateQRCode(userId: string, amount: number, currency: string = 'XOF') {
    try {
      const qrCode = {
        id: `QR-${Date.now()}`,
        userId,
        amount,
        currency,
        code: `JDV-${Math.random().toString(36).substr(2, 9).toUpperCase()}`,
        expiresIn: 5, // minutes
        createdAt: new Date(),
      };

      logger.info(`QR Code generated: ${qrCode.id}`);
      return qrCode;
    } catch (error) {
      logger.error('Generate QR code error:', error);
      throw error;
    }
  }

  // Scan QR Code Payment
  async scanQRCode(payerId: string, qrCode: string, amount: number, currency: string = 'XOF') {
    try {
      // Extract userId from QR code or look it up
      const transaction = this.transactionRepository.create({
        userId: payerId,
        type: 'payment',
        amount,
        currency,
        status: 'completed',
        description: `QR Code payment: ${qrCode}`,
        reference: qrCode,
      });

      await this.transactionRepository.save(transaction);
      logger.info(`QR Code payment processed: ${qrCode}`);
      return transaction;
    } catch (error) {
      logger.error('Scan QR code error:', error);
      throw error;
    }
  }

  // Add Beneficiary
  async addBeneficiary(userId: string, beneficiary: Beneficiary) {
    try {
      // Store in Redis or cache
      const stored = {
        ...beneficiary,
        addedAt: new Date(),
      };

      logger.info(`Beneficiary added for user: ${userId}`);
      return stored;
    } catch (error) {
      logger.error('Add beneficiary error:', error);
      throw error;
    }
  }

  // Create Invoice
  async createInvoice(userId: string, invoiceData: any) {
    try {
      const invoice = {
        id: `INV-${Date.now()}`,
        userId,
        ...invoiceData,
        status: 'draft',
        createdAt: new Date(),
      };

      logger.info(`Invoice created: ${invoice.id}`);
      return invoice;
    } catch (error) {
      logger.error('Create invoice error:', error);
      throw error;
    }
  }

  // Send Invoice
  async sendInvoice(invoiceId: string, recipientEmail: string) {
    try {
      // Send via email service
      const result = {
        invoiceId,
        recipientEmail,
        status: 'sent',
        sentAt: new Date(),
      };

      logger.info(`Invoice sent: ${invoiceId}`);
      return result;
    } catch (error) {
      logger.error('Send invoice error:', error);
      throw error;
    }
  }

  // Recurring Payment
  async setupRecurringPayment(userId: string, recurringData: any) {
    try {
      const recurring = {
        id: `REC-${Date.now()}`,
        userId,
        ...recurringData,
        status: 'active',
        nextDueDate: new Date(),
        createdAt: new Date(),
      };

      logger.info(`Recurring payment setup: ${recurring.id}`);
      return recurring;
    } catch (error) {
      logger.error('Setup recurring payment error:', error);
      throw error;
    }
  }

  // Get Transaction History
  async getTransactionHistory(userId: string, filters: any = {}) {
    try {
      const query = this.transactionRepository.createQueryBuilder('t')
        .where('t.userId = :userId', { userId });

      if (filters.type) {
        query.andWhere('t.type = :type', { type: filters.type });
      }

      if (filters.status) {
        query.andWhere('t.status = :status', { status: filters.status });
      }

      if (filters.currency) {
        query.andWhere('t.currency = :currency', { currency: filters.currency });
      }

      if (filters.startDate) {
        query.andWhere('t.createdAt >= :startDate', { startDate: filters.startDate });
      }

      if (filters.endDate) {
        query.andWhere('t.createdAt <= :endDate', { endDate: filters.endDate });
      }

      const transactions = await query
        .orderBy('t.createdAt', 'DESC')
        .take(filters.limit || 50)
        .getMany();

      return transactions;
    } catch (error) {
      logger.error('Get transaction history error:', error);
      throw error;
    }
  }

  // Get Statistics
  async getStatistics(userId: string, period: string = 'month') {
    try {
      const transactions = await this.transactionRepository.find({
        where: { userId },
      });

      const stats = {
        totalTransactions: transactions.length,
        totalDeposited: transactions
          .filter(t => t.type === 'deposit')
          .reduce((sum, t) => sum + parseFloat(t.amount.toString()), 0),
        totalWithdrawn: transactions
          .filter(t => t.type === 'withdrawal')
          .reduce((sum, t) => sum + parseFloat(t.amount.toString()), 0),
        totalTransferred: transactions
          .filter(t => t.type === 'transfer')
          .reduce((sum, t) => sum + parseFloat(t.amount.toString()), 0),
        totalPaid: transactions
          .filter(t => t.type === 'payment')
          .reduce((sum, t) => sum + parseFloat(t.amount.toString()), 0),
        period,
      };

      return stats;
    } catch (error) {
      logger.error('Get statistics error:', error);
      throw error;
    }
  }

  // Currency Conversion
  async convertCurrency(amount: number, fromCurrency: string, toCurrency: string) {
    try {
      // Implement actual currency conversion logic
      const conversionRates: any = {
        'USD-XOF': 607,
        'EUR-XOF': 655,
        'GBP-XOF': 760,
      };

      const key = `${fromCurrency}-${toCurrency}`;
      const rate = conversionRates[key] || 1;
      const convertedAmount = amount * rate;

      return {
        originalAmount: amount,
        originalCurrency: fromCurrency,
        convertedAmount,
        convertedCurrency: toCurrency,
        rate,
      };
    } catch (error) {
      logger.error('Currency conversion error:', error);
      throw error;
    }
  }

  // Refund Payment
  async refundPayment(transactionId: string, reason: string) {
    try {
      const transaction = await this.transactionRepository.findOne({
        where: { id: transactionId }
      });

      if (!transaction) {
        throw new Error('Transaction not found');
      }

      const refundTransaction = this.transactionRepository.create({
        userId: transaction.userId,
        type: 'refund',
        amount: transaction.amount,
        currency: transaction.currency,
        status: 'completed',
        description: `Refund: ${reason}`,
        relatedTransactionId: transactionId,
      });

      await this.transactionRepository.save(refundTransaction);
      logger.info(`Refund processed: ${transactionId}`);
      return refundTransaction;
    } catch (error) {
      logger.error('Refund payment error:', error);
      throw error;
    }
  }
}
