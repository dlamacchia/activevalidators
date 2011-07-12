module ActiveModel
  module Validations
    class TrackingNumberValidator < EachValidator
      def validate_each(record, attribute, value)
        carrier = options[:carrier]
        raise "Carrier option required" unless carrier
        method = "valid_#{carrier.to_s}?"
        raise "Tracking number validation not supported for carrier #{carrier}" unless self.respond_to?(method)
        record.errors.add(attribute) unless self.send(method, value)
      end

      UPS_REGEXES = [ /^1Z[a-zA-Z0-9]{16}$/, /^[a-zA-Z0-9]{12}$/, /^[a-zA-Z0-9]{9}$/, /^T[a-zA-Z0-9]{10}$/ ]
      def valid_ups?(value)
        !!UPS_REGEXES.detect { |fmt| value.match(fmt) }
      end

      def valid_usps?(value)
        uss228?(value) || uss39?(value)
      end

      def uss228?(value)
        value[-1].to_i == usps_mod10(value[0..2].reverse)
      end

      USS39_REGEX = /^[a-zA-Z0-9]{2}(\d{8})(\d)US$/
      def uss39?(value)
        m = value.match(USS39_REGEX)
        # it appears to be valid for a USS39 barcode's checkdigit to be calculated with either the usps mod 10
        # algorithm or the usps mod 11.
        m.present? && (m[2].to_i == usps_mod10(m[1]) || m[2].to_i == usps_mod11(m[1]))
      end

      MOD10_WEIGHTS = [3,1]
      def usps_mod10(chars)
        10 - weighted_sum(chars, MOD10_WEIGHTS) % 10
      end

      MOD11_WEIGHTS = [8,6,4,2,3,5,9,7]
      def usps_mod11(chars)
        mod = weighted_sum(chars, MOD11_WEIGHTS) % 11
        case mod
        when 0 then 5
        when 1 then 0
        else 11 - mod
        end
      end

      # takes a string containing digits and calculates a checksum using the provided weight array
      # cycles the weight array if it's not long enough
      def weighted_sum(value, weights)
        digits = value.split('').map { |d| d.to_i }
        weights = weights.cycle.take(digits.count) if weights.count < digits.count
        digits.zip(weights).inject(0) { |s,p| s + p[0] * p[1] }
      end
    end
  end
end
